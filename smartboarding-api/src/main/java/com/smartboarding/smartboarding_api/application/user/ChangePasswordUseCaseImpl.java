package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.ChangePasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
public class ChangePasswordUseCaseImpl implements ChangePasswordUseCase {

    private final UserRepositoryPort userRepository;
    private final PasswordEncoder passwordEncoder;

    public ChangePasswordUseCaseImpl(UserRepositoryPort userRepository,
                                     PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void changePassword(UUID userId, String currentPassword, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        if (!user.hasPassword()) {
            throw new ConflictException("NO_PASSWORD_SET",
                    "Você entrou pelo Google e ainda não tem senha. Crie uma primeiro.");
        }

        // A prova de posse e o que separa trocar a senha de tomar a conta: sem
        // ela, quem pegasse o celular desbloqueado trocaria a senha na hora.
        if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
            log.warn("Troca de senha recusada para o usuário {}: senha atual errada", userId);
            throw new BadRequestException("INVALID_CURRENT_PASSWORD",
                    "Senha atual incorreta.");
        }

        if (passwordEncoder.matches(newPassword, user.getPassword())) {
            throw new BadRequestException("SAME_PASSWORD",
                    "A nova senha precisa ser diferente da atual.");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        log.info("Senha trocada para o usuário {}", userId);
    }
}
