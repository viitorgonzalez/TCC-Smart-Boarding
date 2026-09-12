package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;
import com.smartboarding.smartboarding_api.domain.notification.port.out.NotificationRepositoryPort;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public class NotificationRepositoryAdapter implements NotificationRepositoryPort {

    private final NotificationJpaRepository jpa;

    public NotificationRepositoryAdapter(NotificationJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public Notification save(Notification notification) { return jpa.save(notification); }
    @Override
    public List<Notification> findVisible(java.util.Collection<UUID> routeIds, LocalDateTime now) {
        return routeIds.isEmpty()
                ? jpa.findVisibleGeneralOnly(now)
                : jpa.findVisibleForRoutes(routeIds, now);
    }
    @Override public List<Notification> findAll() { return jpa.findAllByOrderByCreatedAtDesc(); }
    @Override public void deleteAllById(List<UUID> ids) { jpa.deleteAllById(ids); }
}
