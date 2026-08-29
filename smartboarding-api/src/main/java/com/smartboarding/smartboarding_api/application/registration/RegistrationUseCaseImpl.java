package com.smartboarding.smartboarding_api.application.registration;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ApproveRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ListPendingRegistrationsUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.RejectRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ResendCodeUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ValidateTokenUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.VerifyInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
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
        SubmitRegistrationUseCase, ListPendingRegistrationsUseCase, ApproveRegistrationUseCase, RejectRegistrationUseCase, ResendCodeUseCase,
        VerifyInviteCodeUseCase {

    private static final long TOKEN_TTL_DAYS = 7;
    private static final long CODE_TTL_MINUTES = 15;
    private static final int MAX_CODE_ATTEMPTS = 5;
    private static final long RESEND_COOLDOWN_SECONDS = 60;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RegistrationRequestRepositoryPort registrationRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;
    private final UserRepositoryPort userRepository;

    public RegistrationUseCaseImpl(RegistrationRequestRepositoryPort registrationRepository,
                                   InstitutionRepositoryPort institutionRepository,
                                   EmailPort emailPort,
                                   PasswordEncoder passwordEncoder,
                                   UserRepositoryPort userRepository) {
        this.registrationRepository = registrationRepository;
        this.institutionRepository = institutionRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public void generateInvite(String email) {
        if (userRepository.existsByEmail(email)) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "E-mail já cadastrado: " + email);
        }

        String token = generateToken();
        String code = generateCode();
        RegistrationRequest request = RegistrationRequest.builder()
                .email(email)
                .token(token)
                .tokenExpiresAt(LocalDateTime.now().plusDays(TOKEN_TTL_DAYS))
                .codeHash(passwordEncoder.encode(code))
                .codeExpiresAt(LocalDateTime.now().plusMinutes(CODE_TTL_MINUTES))
                .status(RegistrationStatus.INVITED)
                .build();
        registrationRepository.save(request);

        // Código em vez de link: App Link exige domínio publicado e verificado,
        // pendência de deploy. Validade curta e limite de tentativas compensam a
        // entropia menor que a do token.
        sendEmailBestEffort(email, RegistrationEmails.VERIFICATION_SUBJECT,
                RegistrationEmails.verificationCode(code, CODE_TTL_MINUTES));
        log.info("Convite de cadastro gerado pra {}", email);
    }

    @Override
    @Transactional
    public void resendCode(String email) {
        // Endpoint público: responder igual com e sem convite evita enumerar
        // quem tem cadastro aberto.
        var found = registrationRepository.findTopByEmailOrderByCreatedAtDesc(email);
        if (found.isEmpty()) {
            log.info("Reenvio de código pedido pra e-mail sem convite");
            return;
        }

        RegistrationRequest request = found.get();
        if (request.getStatus() == RegistrationStatus.APPROVED) {
            log.info("Reenvio de código ignorado, cadastro já aprovado");
            return;
        }
        // Silencioso como os ramos acima: um 400 aqui viraria detector de e-mail.
        if (isWithinResendCooldown(request)) {
            log.info("Reenvio de código ignorado, dentro do cooldown");
            return;
        }

        String code = generateCode();
        request.setCodeHash(passwordEncoder.encode(code));
        request.setCodeExpiresAt(LocalDateTime.now().plusMinutes(CODE_TTL_MINUTES));
        request.setCodeAttempts(0);
        // Renova o token junto: a negação pode chegar depois dos 7 dias (RN14) e
        // o código novo entregaria um token vencido, sem saída pro aluno.
        request.setTokenExpiresAt(LocalDateTime.now().plusDays(TOKEN_TTL_DAYS));
        registrationRepository.save(request);

        sendEmailBestEffort(email, RegistrationEmails.VERIFICATION_SUBJECT,
                RegistrationEmails.verificationCode(code, CODE_TTL_MINUTES));
        log.info("Código de verificação reenviado pra {}", email);
    }

    // Sem isso o endpoint público vira um jeito de inundar a caixa de entrada de
    // qualquer aluno com convite aberto.
    private boolean isWithinResendCooldown(RegistrationRequest request) {
        if (request.getCodeExpiresAt() == null) {
            return false;
        }
        LocalDateTime issuedAt = request.getCodeExpiresAt().minusMinutes(CODE_TTL_MINUTES);
        return LocalDateTime.now().isBefore(issuedAt.plusSeconds(RESEND_COOLDOWN_SECONDS));
    }

    // O envio roda dentro da transação: deixar a exceção subir desfazia a ação
    // inteira e virava 500 genérico. Quem não recebeu o e-mail pede outro código.
    private void sendEmailBestEffort(String to, String subject, String htmlBody) {
        try {
            emailPort.send(to, subject, htmlBody);
        } catch (Exception e) {
            log.error("Falha ao enviar e-mail '{}' — a ação foi mantida: {}", subject, e.getMessage());
        }
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    private String generateCode() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    // Sem @Transactional de propósito: o contador é gravado e a exceção lançada em
    // seguida. Numa transação única o rollback descartaria o incremento e
    // MAX_CODE_ATTEMPTS nunca seria atingido — força bruta livre.
    @Override
    public String verifyCode(String email, String code) {
        RegistrationRequest request = registrationRepository.findTopByEmailOrderByCreatedAtDesc(email)
                .orElseThrow(() -> new NotFoundException("Convite não encontrado"));

        if (request.getStatus() == RegistrationStatus.APPROVED) {
            throw new BadRequestException("ALREADY_APPROVED", "Cadastro já aprovado");
        }
        if (request.isCodeExpired()) {
            throw new BadRequestException("CODE_EXPIRED", "Código expirado, peça um novo convite");
        }
        if (request.getCodeAttempts() >= MAX_CODE_ATTEMPTS) {
            throw new BadRequestException("TOO_MANY_ATTEMPTS", "Muitas tentativas, peça um novo convite");
        }
        if (!passwordEncoder.matches(code, request.getCodeHash())) {
            request.setCodeAttempts(request.getCodeAttempts() + 1);
            registrationRepository.save(request);
            throw new BadRequestException("INVALID_CODE", "Código inválido");
        }

        // Uso único: código que segue valendo é replayável se vazar, e a contagem
        // velha encurtaria o orçamento da próxima verificação.
        request.setCodeHash(null);
        request.setCodeExpiresAt(null);
        request.setCodeAttempts(0);
        registrationRepository.save(request);

        return request.getToken();
    }

    @Override
    public RegistrationRequest validateToken(String token) {
        RegistrationRequest request = registrationRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Convite não encontrado"));
        if (request.isTokenExpired()) {
            throw new BadRequestException("TOKEN_EXPIRED", "Convite expirado");
        }
        // RN14: REJECTED continua válido (reenvio reabre). Só APPROVED é terminal —
        // senão um resubmit sobrescreveria um pedido já virado User.
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
        request.setRejectionReason(null);

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

        // A instituição escolhida no cadastro precisa vir junto (RN15). Revalidada
        // aqui porque pode ter sido removida entre o envio e a aprovação.
        Institution institution = institutionRepository.findById(request.getInstitutionId())
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));

        User user = User.builder()
                .email(request.getEmail())
                .password(request.getPasswordHash())
                .role(Role.STUDENT)
                .fullName(request.getFullName())
                .course(request.getCourse())
                .institutionId(institution.getId())
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
    public void reject(UUID id, String reason) {
        // Sem motivo o reenvio (RN14) vira tentativa às cegas.
        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("REASON_REQUIRED", "Motivo da negação é obrigatório");
        }

        RegistrationRequest request = registrationRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Pedido de cadastro não encontrado"));
        if (request.getStatus() != RegistrationStatus.PENDING) {
            throw new ConflictException("NOT_PENDING", "Pedido de cadastro não está pendente");
        }

        String trimmedReason = reason.trim();
        request.setStatus(RegistrationStatus.REJECTED);
        request.setRejectionReason(trimmedReason);
        registrationRepository.save(request);

        sendEmailBestEffort(request.getEmail(), RegistrationEmails.REJECTED_SUBJECT,
                RegistrationEmails.rejected(trimmedReason));
        log.info("Cadastro negado: {}", request.getEmail());
    }
}
