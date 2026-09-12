package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.SignupUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class SignupUseCaseImpl implements SignupUseCase {

    private final UserRepositoryPort userRepository;
    private final PasswordEncoder passwordEncoder;
    private final String bootstrapAdminEmail;

    public SignupUseCaseImpl(UserRepositoryPort userRepository,
                             PasswordEncoder passwordEncoder,
                             @Value("${app.bootstrap-admin-email:}") String bootstrapAdminEmail) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.bootstrapAdminEmail = bootstrapAdminEmail;
    }

    @Override
    @Transactional
    public User signup(User user, String rawPassword) {
        // O papel e cravado aqui, nao vem do request: aceitar o que o cliente
        // mandar deixaria qualquer um criar conta de admin por este endpoint,
        // que e publico.
        //
        // A unica excecao e o bootstrap, e ela se fecha sozinha: num banco novo
        // nao existe admin, logo nao ha quem promova. A variavel CONCEDE o papel
        // a uma conta que a propria pessoa criou -- nao cria conta nenhuma -- e
        // no instante em que existe um admin a condicao nunca mais e verdadeira.
        user.setRole(ehOBootstrap(user.getEmail()) ? Role.ADMIN : Role.STUDENT);

        // Login e recuperação de senha respondem igual havendo conta ou não, pra
        // não revelar quais e-mails existem. Aqui é o oposto de propósito: quem
        // ja tem conta PRECISA saber, senao acha que criou uma nova e nao
        // consegue entrar. A alternativa -- fingir sucesso -- troca um vazamento
        // pequeno por um usuario travado sem entender o motivo.
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS",
                    "Esse e-mail já tem conta. Entre ou recupere a senha.");
        }

        user.setPassword(passwordEncoder.encode(rawPassword));
        // Nasce ativa e SEM rota: o acesso a rota vem depois, pelo codigo.
        user.setActive(true);

        User saved = userRepository.save(user);
        log.info("Conta criada por cadastro próprio: {}", maskEmail(saved.getEmail()));
        return saved;
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        return email.charAt(0) + "***" + email.substring(email.indexOf('@'));
    }

    private boolean ehOBootstrap(String email) {
        return bootstrapAdminEmail != null
                && !bootstrapAdminEmail.isBlank()
                && bootstrapAdminEmail.equalsIgnoreCase(email)
                && userRepository.countAdmins() == 0;
    }
}
