package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ScheduledNotificationJpaRepository
        extends JpaRepository<ScheduledNotification, UUID> {

    List<ScheduledNotification> findAllByRouteIdOrderBySendAtAsc(UUID routeId);

    List<ScheduledNotification> findAllByActiveTrue();
}
