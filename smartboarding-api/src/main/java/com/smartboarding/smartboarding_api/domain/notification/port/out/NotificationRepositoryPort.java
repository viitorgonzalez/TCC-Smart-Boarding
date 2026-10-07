package com.smartboarding.smartboarding_api.domain.notification.port.out;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface NotificationRepositoryPort {
    Notification save(Notification notification);

    List<Notification> findVisible(java.util.Collection<UUID> routeIds, LocalDateTime now);

    List<Notification> findAll();
    void deleteAllById(List<UUID> ids);
}
