package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
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

    public GoogleSignInUseCaseImpl(GoogleTokenVerifierPort verifier,
                                   UserRepositoryPort userRepository) {
        this.verifier = verifier;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public User signIn(String idToken) {
        GoogleTokenVerifierPort.GoogleAccount conta = verifier.verify(idToken);

        // ESTA checagem e o que separa login social de sequestro de conta. Sem
        // ela, alguem cria um Google com o e-mail de outra pessoa, entra aqui e
        // o vinculo por e-mail abaixo entrega a conta dela de bandeja.
        if (!conta.emailVerified()) {
            throw new UnauthorizedException(
                    "Seu e-mail não está verificado no Google.");
        }

        // Ja vinculado: caminho normal de quem so esta voltando.
        Optional<User> porGoogle = userRepository.findByGoogleId(conta.googleId());
        if (porGoogle.isPresent()) {
            return porGoogle.get();
        }

        // Mesmo e-mail, conta criada por senha: vincula em vez de recusar ou
        // duplicar. Duplicar deixaria o aluno com duas contas e a lista dele
        // partida entre as duas.
        Optional<User> porEmail = userRepository.findByEmail(conta.email());
        if (porEmail.isPresent()) {
            User existente = porEmail.get();
            existente.setGoogleId(conta.googleId());
            User salvo = userRepository.save(existente);
            log.info("Conta existente vinculada ao Google: {}", maskEmail(conta.email()));
            return salvo;
        }

        User novo = userRepository.save(User.builder()
                .email(conta.email())
                .fullName(conta.fullName())
                .googleId(conta.googleId())
                // Sem senha local: ele define uma depois, se quiser.
                .role(Role.STUDENT)
                .isActive(true)
                .build());
        log.info("Conta criada pelo Google: {}", maskEmail(conta.email()));
        return novo;
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        return email.charAt(0) + "***" + email.substring(email.indexOf('@'));
    }
}
