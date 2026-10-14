package com.smartboarding.smartboarding_api.domain.notification.port.in;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;

import java.util.List;
import java.util.UUID;

public interface ManageScheduledNotificationUseCase {
    List<ScheduledNotification> listByRoute(UUID routeId);
    ScheduledNotification save(ScheduledNotification notification);
    ScheduledNotification toggle(UUID id, boolean active);

    ScheduledNotification findById(UUID id);
    void delete(UUID id);

    int dispatchDue();
}
