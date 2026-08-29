package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import com.smartboarding.smartboarding_api.domain.notification.port.in.ManageScheduledNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.out.ScheduledNotificationRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class ScheduledNotificationUseCaseImpl implements ManageScheduledNotificationUseCase {

    private final ScheduledNotificationRepositoryPort repository;
    private final PublishNotificationUseCase publishNotificationUseCase;
    private final Clock clock;

    public ScheduledNotificationUseCaseImpl(ScheduledNotificationRepositoryPort repository,
                                            PublishNotificationUseCase publishNotificationUseCase,
                                            Clock clock) {
        this.repository = repository;
        this.publishNotificationUseCase = publishNotificationUseCase;
        this.clock = clock;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ScheduledNotification> listByRoute(UUID routeId) {
        return repository.findAllByRouteId(routeId);
    }

    @Override
    @Transactional
    public ScheduledNotification save(ScheduledNotification notification) {
        return repository.save(notification);
    }

    @Override
    @Transactional
    public ScheduledNotification toggle(UUID id, boolean active) {
        ScheduledNotification found = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Aviso automático não encontrado"));
        found.setActive(active);
        return repository.save(found);
    }

    @Override
    @Transactional
    public void delete(UUID id) {
        repository.deleteById(id);
    }

    @Override
    @Scheduled(cron = "0 */5 * * * *")
    @Transactional
    public int dispatchDue() {
        LocalDateTime now = LocalDateTime.now(clock);
        List<ScheduledNotification> due = repository.findAllActive().stream()
                .filter(n -> n.isDue(now))
                .toList();

        for (ScheduledNotification scheduled : due) {
            try {
                publishNotificationUseCase.publish(scheduled.getTitle(), scheduled.getBody(),
                        scheduled.getRouteId(), scheduled.getDurationHours(), null);
                // Marcado depois do envio: se a publicação falhar, o próximo
                // tique tenta de novo em vez de pular o dia.
                scheduled.setLastSentAt(now);
                repository.save(scheduled);
            } catch (Exception e) {
                log.error("Falha ao disparar aviso automático {}: {}",
                        scheduled.getId(), e.getMessage());
            }
        }
        if (!due.isEmpty()) {
            log.info("{} aviso(s) automático(s) disparado(s)", due.size());
        }
        return due.size();
    }
}
