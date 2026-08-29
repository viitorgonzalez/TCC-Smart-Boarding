package com.smartboarding.smartboarding_api.domain.notification.port.out;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ScheduledNotificationRepositoryPort {
    ScheduledNotification save(ScheduledNotification notification);
    Optional<ScheduledNotification> findById(UUID id);
    List<ScheduledNotification> findAllByRouteId(UUID routeId);
    List<ScheduledNotification> findAllActive();
    void deleteById(UUID id);
}
