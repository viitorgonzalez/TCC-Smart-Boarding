package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import com.smartboarding.smartboarding_api.domain.notification.port.out.ScheduledNotificationRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class ScheduledNotificationRepositoryAdapter
        implements ScheduledNotificationRepositoryPort {

    private final ScheduledNotificationJpaRepository jpa;

    public ScheduledNotificationRepositoryAdapter(ScheduledNotificationJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public ScheduledNotification save(ScheduledNotification n) { return jpa.save(n); }
    @Override public Optional<ScheduledNotification> findById(UUID id) { return jpa.findById(id); }
    @Override public List<ScheduledNotification> findAllByRouteId(UUID routeId) {
        return jpa.findAllByRouteIdOrderBySendAtAsc(routeId);
    }
    @Override public List<ScheduledNotification> findAllActive() { return jpa.findAllByActiveTrue(); }
    @Override public void deleteById(UUID id) { jpa.deleteById(id); }
}
