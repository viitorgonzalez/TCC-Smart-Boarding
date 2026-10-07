package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.GoogleSignInUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.GoogleTokenVerifierPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Slf4j
@Service
public class GoogleSignInUseCaseImpl implements GoogleSignInUseCase {

    private final GoogleTokenVerifierPort verifier;
    private final UserRepositoryPort userRepository;
    private final BootstrapAdminPolicy bootstrapAdminPolicy;

    public GoogleSignInUseCaseImpl(GoogleTokenVerifierPort verifier,
                                   UserRepositoryPort userRepository,
                                   BootstrapAdminPolicy bootstrapAdminPolicy) {
        this.verifier = verifier;
        this.userRepository = userRepository;
        this.bootstrapAdminPolicy = bootstrapAdminPolicy;
    }

    @Override
    @Transactional
    public User signIn(String idToken) {
        GoogleTokenVerifierPort.GoogleAccount conta = verifier.verify(idToken);

        if (!conta.emailVerified()) {
            throw new UnauthorizedException(
                    "Seu e-mail não está verificado no Google.");
        }

        Optional<User> porGoogle = userRepository.findByGoogleId(conta.googleId());
        if (porGoogle.isPresent()) {
            return garantirAtiva(porGoogle.get());
        }

        Optional<User> porEmail = userRepository.findByEmail(conta.email());
        if (porEmail.isPresent()) {
            User existente = porEmail.get();
            existente.setGoogleId(conta.googleId());
            User salvo = userRepository.save(garantirAtiva(existente));
            log.info("Conta existente vinculada ao Google: {}", maskEmail(conta.email()));
            return salvo;
        }

        User novo = userRepository.save(User.builder()
                .email(conta.email())
                .fullName(conta.fullName())
                .googleId(conta.googleId())
                .role(bootstrapAdminPolicy.roleForNewAccount(conta.email()))
                .isActive(true)
                .build());
        log.info("Conta criada pelo Google: {}", maskEmail(conta.email()));
        return novo;
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        return email.charAt(0) + "***" + email.substring(email.indexOf('@'));
    }

    private User garantirAtiva(User user) {
        if (!user.isActive()) {
            throw new UnauthorizedException("Conta desativada. Procure o administrador.");
        }
        return user;
    }
}
