package com.smartboarding.smartboarding_api.domain.notification.port.in;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.util.UUID;

public interface PublishNotificationUseCase {
    Notification publish(String title, String body, UUID routeId, Integer durationHours, UUID authorId);

    Notification publishIndependente(String title, String body, UUID routeId,
                                     Integer durationHours, UUID authorId);

    void deleteAll(java.util.List<UUID> ids);
}
