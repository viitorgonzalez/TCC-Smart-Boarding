package com.smartboarding.smartboarding_api.application.emailchange;

import com.smartboarding.smartboarding_api.domain.emailchange.entity.EmailChangeRequest;
import com.smartboarding.smartboarding_api.domain.emailchange.port.in.ConfirmEmailChangeUseCase;
import com.smartboarding.smartboarding_api.domain.emailchange.port.in.RequestEmailChangeUseCase;
import com.smartboarding.smartboarding_api.domain.emailchange.port.out.EmailChangeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
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
import java.time.Clock;
import java.time.LocalDateTime;

import java.util.UUID;

@Slf4j
@Service
public class EmailChangeUseCaseImpl implements RequestEmailChangeUseCase, ConfirmEmailChangeUseCase {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final EmailChangeRepositoryPort changeRepository;
    private final UserRepositoryPort userRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final long codeTtlMinutes;
    private final int maxAttempts;
    private final long resendCooldownSeconds;

    public EmailChangeUseCaseImpl(EmailChangeRepositoryPort changeRepository,
                                  UserRepositoryPort userRepository,
                                  EmailPort emailPort,
                                  PasswordEncoder passwordEncoder,
                                  Clock clock,
                                  @Value("${app.email-change.code-ttl-minutes}") long codeTtlMinutes,
                                  @Value("${app.email-change.max-attempts}") int maxAttempts,
                                  @Value("${app.email-change.resend-cooldown-seconds}") long resendCooldownSeconds) {
        this.changeRepository = changeRepository;
        this.userRepository = userRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
        this.codeTtlMinutes = codeTtlMinutes;
        this.maxAttempts = maxAttempts;
        this.resendCooldownSeconds = resendCooldownSeconds;
    }

    @Override
    @Transactional
    public void request(UUID userId, String newEmail) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        String normalizado = newEmail == null ? "" : newEmail.trim().toLowerCase();
        if (normalizado.isBlank()) {
            throw new BadRequestException("INVALID_EMAIL", "Informe o novo e-mail.");
        }
        if (normalizado.equalsIgnoreCase(user.getEmail())) {
            throw new BadRequestException("SAME_EMAIL", "Esse já é o seu e-mail atual.");
        }
        if (userRepository.existsByEmail(normalizado)) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "Esse e-mail já está em uso.");
        }

        LocalDateTime now = LocalDateTime.now(clock);
        if (isWithinCooldown(userId, now)) {
            throw new BadRequestException("TOO_SOON",
                    "Aguarde um pouco antes de pedir outro código.");
        }

        changeRepository.invalidateAllForUser(userId, now);

        String code = generateCode();
        changeRepository.save(EmailChangeRequest.builder()
                .userId(userId)
                .newEmail(normalizado)
                .codeHash(passwordEncoder.encode(code))
                .expiresAt(now.plusMinutes(codeTtlMinutes))
                .createdAt(now)
                .build());

        sendEmailBestEffort(normalizado, EmailChangeEmails.CODE_SUBJECT,
                EmailChangeEmails.code(code, codeTtlMinutes));
    }

    private boolean isWithinCooldown(UUID userId, LocalDateTime now) {
        return changeRepository.findLatestOpenByUserId(userId)
                .map(EmailChangeRequest::getCreatedAt)
                .filter(created -> created.plusSeconds(resendCooldownSeconds).isAfter(now))
                .isPresent();
    }

    @Override
    public void confirm(UUID userId, String code) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        EmailChangeRequest request = changeRepository.findLatestOpenByUserId(userId)
                .orElseThrow(this::invalidCode);

        LocalDateTime now = LocalDateTime.now(clock);
        if (request.isExpired(now)) {
            throw new BadRequestException("CODE_EXPIRED", "Código expirado, peça um novo.");
        }
        if (request.getAttempts() >= maxAttempts) {
            throw new BadRequestException("TOO_MANY_ATTEMPTS", "Muitas tentativas, peça um novo código.");
        }
        if (!passwordEncoder.matches(code, request.getCodeHash())) {
            request.setAttempts(request.getAttempts() + 1);
            changeRepository.save(request);
            throw invalidCode();
        }

        if (userRepository.existsByEmail(request.getNewEmail())) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "Esse e-mail já está em uso.");
        }

        String emailAntigo = user.getEmail();
        user.setEmail(request.getNewEmail());
        userRepository.save(user);

        request.setUsedAt(now);
        changeRepository.save(request);
        changeRepository.invalidateAllForUser(userId, now);

        log.info("E-mail trocado para o usuário {}", userId);
        sendEmailBestEffort(emailAntigo, EmailChangeEmails.CHANGED_SUBJECT,
                EmailChangeEmails.changed(request.getNewEmail()));
    }

    private void sendEmailBestEffort(String to, String subject, String htmlBody) {
        try {
            emailPort.send(to, subject, htmlBody);
        } catch (Exception e) {
            log.error("Falha ao enviar e-mail de troca de endereço: {}", e.getMessage());
        }
    }

    private String generateCode() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    private BadRequestException invalidCode() {
        return new BadRequestException("INVALID_CODE", "Código inválido ou expirado.");
    }
}
