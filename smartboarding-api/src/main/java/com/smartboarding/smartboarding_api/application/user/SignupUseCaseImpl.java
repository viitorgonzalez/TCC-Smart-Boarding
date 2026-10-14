package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.SignupUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class SignupUseCaseImpl implements SignupUseCase {

    private final UserRepositoryPort userRepository;
    private final PasswordEncoder passwordEncoder;
    private final BootstrapAdminPolicy bootstrapAdminPolicy;

    public SignupUseCaseImpl(UserRepositoryPort userRepository,
                             PasswordEncoder passwordEncoder,
                             BootstrapAdminPolicy bootstrapAdminPolicy) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.bootstrapAdminPolicy = bootstrapAdminPolicy;
    }

    @Override
    @Transactional
    public User signup(User user, String rawPassword) {
        user.setRole(bootstrapAdminPolicy.roleForNewAccount(user.getEmail()));

        if (userRepository.existsByEmail(user.getEmail())) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS",
                    "Esse e-mail já tem conta. Entre ou recupere a senha.");
        }

        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setActive(true);

        User saved = userRepository.save(user);
        log.info("Conta criada por cadastro próprio: {}", maskEmail(saved.getEmail()));
        return saved;
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        return email.charAt(0) + "***" + email.substring(email.indexOf('@'));
    }
}
