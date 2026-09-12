package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusAction;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;
import com.smartboarding.smartboarding_api.domain.user.port.in.ManageUserStatusUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserStatusLogRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@Slf4j
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

        // Desativar existe pra conter aluno que abusa da lista. Valendo pra
        // admin, o primeiro clique errado tranca quem administra o sistema pra
        // fora dele -- e não sobra ninguém pra desfazer.
        if (!active && user.getRole() == Role.ADMIN) {
            throw new BadRequestException("CANNOT_DEACTIVATE_ADMIN",
                    "Conta de administrador não pode ser desativada.");
        }
        if (!active && userId.equals(adminId)) {
            throw new BadRequestException("CANNOT_DEACTIVATE_SELF",
                    "Você não pode desativar a própria conta.");
        }

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
    @Transactional
    public User setRole(UUID userId, Role role, UUID adminId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        // Declaracao de estado, nao acao: repetir e no-op. Sair antes de qualquer
        // trava mantem o retry e o duplo toque inofensivos.
        if (user.getRole() == role) {
            return user;
        }

        if (role == Role.STUDENT) {
            if (userId.equals(adminId)) {
                throw new BadRequestException("CANNOT_DEMOTE_SELF",
                        "Você não pode rebaixar a própria conta.");
            }
            // Sem admin nenhum ninguem promove ninguem de volta -- a saida seria
            // editar o banco a mao.
            if (userRepository.countAdmins() <= 1) {
                throw new BadRequestException("LAST_ADMIN",
                        "Este é o único administrador; promova outro antes de rebaixá-lo.");
            }
        }

        // Promover quem esta desativado cria um admin que nao consegue entrar: a
        // tela mostraria acesso concedido e o login negaria.
        if (role == Role.ADMIN && !user.isActive()) {
            throw new BadRequestException("INACTIVE_ACCOUNT",
                    "Conta desativada não pode ser promovida. Reative antes.");
        }

        user.setRole(role);
        User saved = userRepository.save(user);

        logRepository.save(UserStatusLog.builder()
                .userId(userId)
                .adminId(adminId)
                .action(role == Role.ADMIN ? UserStatusAction.PROMOTED : UserStatusAction.DEMOTED)
                .createdAt(LocalDateTime.now(clock))
                .build());

        log.info("Papel de {} alterado para {} por {}", userId, role, adminId);
        return saved;
    }

    @Override
    public List<UserStatusLog> history(UUID userId) {
        return logRepository.findAllByUserId(userId);
    }
}
