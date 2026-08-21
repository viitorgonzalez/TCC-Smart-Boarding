package com.smartboarding.smartboarding_api.application.registration;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ApproveRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ListPendingRegistrationsUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.RejectRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ValidateTokenUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class RegistrationUseCaseImpl implements GenerateInviteUseCase, ValidateTokenUseCase,
        SubmitRegistrationUseCase, ListPendingRegistrationsUseCase, ApproveRegistrationUseCase, RejectRegistrationUseCase {

    private static final long TOKEN_TTL_DAYS = 7;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RegistrationRequestRepositoryPort registrationRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;
    private final UserRepositoryPort userRepository;
    private final String publicBaseUrl;

    public RegistrationUseCaseImpl(RegistrationRequestRepositoryPort registrationRepository,
                                   InstitutionRepositoryPort institutionRepository,
                                   EmailPort emailPort,
                                   PasswordEncoder passwordEncoder,
                                   UserRepositoryPort userRepository,
                                   @Value("${app.public-base-url:https://smartboarding.app}") String publicBaseUrl) {
        this.registrationRepository = registrationRepository;
        this.institutionRepository = institutionRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
        this.userRepository = userRepository;
        this.publicBaseUrl = publicBaseUrl;
    }

    @Override
    @Transactional
    public void generateInvite(String email) {
        if (userRepository.existsByEmail(email)) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "E-mail já cadastrado: " + email);
        }

        String token = generateToken();
        RegistrationRequest request = RegistrationRequest.builder()
                .email(email)
                .token(token)
                .tokenExpiresAt(LocalDateTime.now().plusDays(TOKEN_TTL_DAYS))
                .status(RegistrationStatus.INVITED)
                .build();
        registrationRepository.save(request);

        String link = publicBaseUrl + "/register/" + token;
        emailPort.send(email, "Convite Smart Boarding",
                "<p>Você foi convidado a se cadastrar no Smart Boarding.</p><p><a href=\"" + link + "\">Completar cadastro</a></p>");
        log.info("Convite de cadastro gerado pra {}", email);
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    @Override
    public RegistrationRequest validateToken(String token) {
        RegistrationRequest request = registrationRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Convite não encontrado"));
        if (request.isTokenExpired()) {
            throw new BadRequestException("TOKEN_EXPIRED", "Convite expirado");
        }
        // RN14: REJECTED continua validando (reenvio reabre o cadastro) — só APPROVED é terminal,
        // senão um resubmit sobrescreve um pedido já virado User e o approve() seguinte colide
        // com o UNIQUE(email) de users.
        if (request.getStatus() == RegistrationStatus.APPROVED) {
            throw new BadRequestException("ALREADY_APPROVED", "Cadastro já aprovado");
        }
        return request;
    }

    @Override
    @Transactional
    public RegistrationRequest submitRegistration(String token, SubmitData data) {
        RegistrationRequest request = validateToken(token); // reusa a validação de expiração/existência

        Institution institution = institutionRepository.findById(data.institutionId())
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));

        request.setFullName(data.fullName());
        request.setPasswordHash(passwordEncoder.encode(data.rawPassword()));
        request.setInstitutionId(institution.getId());
        request.setCourse(data.course());
        request.setPhone(data.phone());
        request.setAddress(data.address());
        request.setBirthDate(data.birthDate());
        request.setStatus(RegistrationStatus.PENDING);

        RegistrationRequest saved = registrationRepository.save(request);
        log.info("Cadastro submetido: {}", request.getEmail());
        return saved;
    }

    @Override
    public List<RegistrationRequest> listPending() {
        return registrationRepository.findAllByStatus(RegistrationStatus.PENDING);
    }

    @Override
    @Transactional
    public User approve(UUID id) {
        RegistrationRequest request = registrationRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Pedido de cadastro não encontrado"));

        if (request.getStatus() != RegistrationStatus.PENDING) {
            throw new ConflictException("NOT_PENDING", "Pedido de cadastro não está pendente");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "E-mail já cadastrado: " + request.getEmail());
        }

        // RN14: aprovar é o único ponto em que um RegistrationRequest vira um User de fato —
        // a instituição escolhida no cadastro precisa ser copiada junto (mesma checagem defensiva
        // de submitRegistration, já que o vínculo foi validado na submissão mas pode ter sido
        // removido nesse meio-tempo).
        Institution institution = institutionRepository.findById(request.getInstitutionId())
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));

        User user = User.builder()
                .email(request.getEmail())
                .password(request.getPasswordHash())
                .role(Role.STUDENT)
                .fullName(request.getFullName())
                .course(request.getCourse())
                .institution(institution.getName())
                .phone(request.getPhone())
                .address(request.getAddress())
                .birthDate(request.getBirthDate())
                .isActive(true)
                .build();
        User saved = userRepository.save(user);

        request.setStatus(RegistrationStatus.APPROVED);
        registrationRepository.save(request);
        log.info("Cadastro aprovado, conta criada: {}", request.getEmail());
        return saved;
    }

    @Override
    @Transactional
    public void reject(UUID id) {
        RegistrationRequest request = registrationRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Pedido de cadastro não encontrado"));
        if (request.getStatus() != RegistrationStatus.PENDING) {
            throw new ConflictException("NOT_PENDING", "Pedido de cadastro não está pendente");
        }
        request.setStatus(RegistrationStatus.REJECTED);
        registrationRepository.save(request);
        log.info("Cadastro negado: {}", request.getEmail());
    }
}
