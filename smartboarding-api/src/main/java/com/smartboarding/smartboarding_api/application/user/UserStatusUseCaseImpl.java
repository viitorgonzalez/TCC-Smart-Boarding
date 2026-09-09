package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusAction;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;
import com.smartboarding.smartboarding_api.domain.user.port.in.ManageUserStatusUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserStatusLogRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class UserStatusUseCaseImpl implements ManageUserStatusUseCase {

    private final UserRepositoryPort userRepository;
    private final UserStatusLogRepositoryPort logRepository;
    private final Clock clock;

    public UserStatusUseCaseImpl(UserRepositoryPort userRepository,
                                 UserStatusLogRepositoryPort logRepository,
                                 Clock clock) {
        this.userRepository = userRepository;
        this.logRepository = logRepository;
        this.clock = clock;
    }

    @Override
    @Transactional
    public User setActive(UUID userId, boolean active, UUID adminId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        // Sem mudança real não há o que registrar -- log cheio de repetição
        // esconde a ação que importa.
        if (user.isActive() == active) {
            return user;
        }

        user.setActive(active);
        User saved = userRepository.save(user);

        logRepository.save(UserStatusLog.builder()
                .userId(userId)
                .adminId(adminId)
                .action(active ? UserStatusAction.ACTIVATED : UserStatusAction.DEACTIVATED)
                .createdAt(LocalDateTime.now(clock))
                .build());

        return saved;
    }

    @Override
    public List<UserStatusLog> history(UUID userId) {
        return logRepository.findAllByUserId(userId);
    }
}
