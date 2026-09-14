package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.notification.port.in.SendBroadcastUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.out.DeviceTokenRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.out.FcmPort;
import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;
import com.smartboarding.smartboarding_api.domain.notification.port.in.ListNotificationsUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.out.NotificationRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class NotificationUseCaseImpl implements SendBroadcastUseCase, SendToUserUseCase,
        PublishNotificationUseCase, ListNotificationsUseCase {

    private final FcmPort fcmPort;
    private final DeviceTokenRepositoryPort deviceTokenRepository;
    private final NotificationRepositoryPort notificationRepository;
    private final UserRepositoryPort userRepository;
    private final RouteMemberRepositoryPort routeMemberRepository;
    private final Clock clock;

    public NotificationUseCaseImpl(FcmPort fcmPort,
                                   DeviceTokenRepositoryPort deviceTokenRepository,
                                   NotificationRepositoryPort notificationRepository,
                                   UserRepositoryPort userRepository,
                                   RouteMemberRepositoryPort routeMemberRepository,
                                   Clock clock) {
        this.fcmPort = fcmPort;
        this.deviceTokenRepository = deviceTokenRepository;
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.routeMemberRepository = routeMemberRepository;
        this.clock = clock;
    }

    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Notification publishIndependente(String title, String body, UUID routeId,
                                            Integer durationHours, UUID authorId) {
        return publish(title, body, routeId, durationHours, authorId);
    }

    @Override
    @Transactional
    public Notification publish(String title, String body, UUID routeId,
                                Integer durationHours, UUID authorId) {
        Notification saved = notificationRepository.save(Notification.builder()
                .title(title)
                .body(body)
                .routeId(routeId)
                .createdBy(authorId)
                .expiresAt(durationHours == null
                        ? null
                        : LocalDateTime.now(clock).plusHours(durationHours))
                .build());

        // O push é entrega imediata; o registro é o que sobrevive. Falha de FCM
        // não pode desfazer o aviso — quem não recebeu ainda o vê na caixa.
        try {
            execute(title, body);
        } catch (Exception e) {
            log.error("Aviso gravado, mas o push falhou: {}", e.getMessage());
        }
        return saved;
    }

    @Override
    @Transactional
    public void deleteAll(List<UUID> ids) {
        if (ids.isEmpty()) {
            return;
        }
        notificationRepository.deleteAllById(ids);
        log.info("{} aviso(s) removido(s)", ids.size());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Notification> listFor(UUID requesterId) {
        User requester = userRepository.findById(requesterId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));
        if (requester.getRole() != Role.STUDENT) {
            return notificationRepository.findAll();
        }
        // O aluno ve os avisos de TODAS as rotas dele, mais os gerais. Ate a V22
        // isso vinha da instituicao (RN15); agora vem do vinculo criado pelo
        // codigo da rota.
        List<UUID> routeIds = routeMemberRepository.findAllByUserId(requesterId).stream()
                .map(RouteMember::getRouteId)
                .toList();
        return notificationRepository.findVisible(routeIds, LocalDateTime.now(clock));
    }

    @Override
    public void execute(String title, String body) {
        List<String> tokens = deviceTokenRepository.findAllTokens();
        if (tokens.isEmpty()) {
            log.info("Broadcast ignorado: nenhum dispositivo registrado.");
            return;
        }
        fcmPort.sendToTokens(tokens, title, body);
        log.info("Broadcast enviado para {} dispositivos: {}", tokens.size(), title);
    }

    @Override
    public void execute(UUID userId, String title, String body) {
        List<String> tokens = deviceTokenRepository.findByUserId(userId)
                .stream()
                .map(dt -> dt.getToken())
                .toList();

        if (tokens.isEmpty()) {
            log.info("Notificação ignorada: usuário {} sem dispositivos registrados.", userId);
            return;
        }
        fcmPort.sendToTokens(tokens, title, body);
        log.info("Notificação enviada para usuário {}: {}", userId, title);
    }
}
