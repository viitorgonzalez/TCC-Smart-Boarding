package com.smartboarding.smartboarding_api.application.registration;

import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;

@Slf4j
@Service
public class RegistrationUseCaseImpl implements GenerateInviteUseCase {

    private static final long TOKEN_TTL_DAYS = 7;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RegistrationRequestRepositoryPort registrationRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;

    public RegistrationUseCaseImpl(RegistrationRequestRepositoryPort registrationRepository,
                                   InstitutionRepositoryPort institutionRepository,
                                   EmailPort emailPort,
                                   PasswordEncoder passwordEncoder) {
        this.registrationRepository = registrationRepository;
        this.institutionRepository = institutionRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void generateInvite(String email) {
        String token = generateToken();
        RegistrationRequest request = RegistrationRequest.builder()
                .email(email)
                .token(token)
                .tokenExpiresAt(LocalDateTime.now().plusDays(TOKEN_TTL_DAYS))
                .status(RegistrationStatus.INVITED)
                .build();
        registrationRepository.save(request);

        String link = "https://smartboarding.app/register/" + token; // domínio real fica pendente do deploy — ver spec §5
        emailPort.send(email, "Convite Smart Boarding",
                "<p>Você foi convidado a se cadastrar no Smart Boarding.</p><p><a href=\"" + link + "\">Completar cadastro</a></p>");
        log.info("Convite de cadastro gerado pra {}", email);
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }
}
