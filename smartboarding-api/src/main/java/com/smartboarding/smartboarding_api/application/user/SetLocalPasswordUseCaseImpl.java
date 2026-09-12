package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.SetLocalPasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
public class SetLocalPasswordUseCaseImpl implements SetLocalPasswordUseCase {

    private final UserRepositoryPort userRepository;
    private final PasswordEncoder passwordEncoder;

    public SetLocalPasswordUseCaseImpl(UserRepositoryPort userRepository,
                                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void setPassword(UUID userId, String rawPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        // Definir, nao trocar. Se ja ha senha, permitir sobrescrever aqui daria
        // troca de senha sem provar posse da antiga -- quem pegasse o celular
        // desbloqueado trocaria a senha e tomaria a conta. Trocar e pelo fluxo
        // de recuperacao, que exige acesso ao e-mail.
        if (user.hasPassword()) {
            throw new ConflictException("PASSWORD_ALREADY_SET",
                    "Você já tem senha. Use 'Esqueci minha senha' para trocar.");
        }

        user.setPassword(passwordEncoder.encode(rawPassword));
        userRepository.save(user);
        log.info("Senha local definida para o usuário {}", userId);
    }
}
