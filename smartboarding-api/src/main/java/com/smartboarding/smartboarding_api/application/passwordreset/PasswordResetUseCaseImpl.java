package com.smartboarding.smartboarding_api.application.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.RequestPasswordResetUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.ResetPasswordUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Service
public class PasswordResetUseCaseImpl implements RequestPasswordResetUseCase, ResetPasswordUseCase {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final PasswordResetRepositoryPort resetRepository;
    private final UserRepositoryPort userRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final long codeTtlMinutes;
    private final int maxAttempts;
    private final long resendCooldownSeconds;

    public PasswordResetUseCaseImpl(PasswordResetRepositoryPort resetRepository,
                                    UserRepositoryPort userRepository,
                                    EmailPort emailPort,
                                    PasswordEncoder passwordEncoder,
                                    Clock clock,
                                    @Value("${app.password-reset.code-ttl-minutes}") long codeTtlMinutes,
                                    @Value("${app.password-reset.max-attempts}") int maxAttempts,
                                    @Value("${app.password-reset.resend-cooldown-seconds}") long resendCooldownSeconds) {
        this.resetRepository = resetRepository;
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
    public void request(String email) {
        Optional<User> found = userRepository.findByEmail(email);
        if (found.isEmpty()) {
            return;
        }
        User user = found.get();
        LocalDateTime now = LocalDateTime.now(clock);

        if (isWithinCooldown(user, now)) {
            return;
        }

        resetRepository.invalidateAllForUser(user.getId(), now);

        String code = generateCode();
        resetRepository.save(PasswordResetRequest.builder()
                .userId(user.getId())
                .codeHash(passwordEncoder.encode(code))
                .expiresAt(now.plusMinutes(codeTtlMinutes))
                .createdAt(now)
                .build());

        sendEmailBestEffort(email, PasswordResetEmails.SUBJECT,
                PasswordResetEmails.code(code, codeTtlMinutes));
    }

    private boolean isWithinCooldown(User user, LocalDateTime now) {
        return resetRepository.findLatestOpenByUserId(user.getId())
                .map(PasswordResetRequest::getCreatedAt)
                .filter(created -> created.plusSeconds(resendCooldownSeconds).isAfter(now))
                .isPresent();
    }

    private void sendEmailBestEffort(String to, String subject, String htmlBody) {
        try {
            emailPort.send(to, subject, htmlBody);
        } catch (Exception e) {
            log.error("Pedido gravado, mas o e-mail de redefinição falhou: {}", e.getMessage());
        }
    }

    private String generateCode() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    @Override
    public void reset(String email, String code, String newPassword) {
        User user = userRepository.findByEmail(email).orElseThrow(this::invalidCode);
        PasswordResetRequest request = resetRepository.findLatestOpenByUserId(user.getId())
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
            resetRepository.save(request);
            throw invalidCode();
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        request.setUsedAt(now);
        resetRepository.save(request);
        resetRepository.invalidateAllForUser(user.getId(), now);
    }

    private BadRequestException invalidCode() {
        return new BadRequestException("INVALID_CODE", "Código inválido ou expirado.");
    }
}
