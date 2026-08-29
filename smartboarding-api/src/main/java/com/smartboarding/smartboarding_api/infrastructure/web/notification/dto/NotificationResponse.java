package com.smartboarding.smartboarding_api.infrastructure.web.notification.dto;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.time.LocalDateTime;
import java.util.UUID;

public record NotificationResponse(UUID id, String title, String body, UUID routeId,
                                   LocalDateTime expiresAt, LocalDateTime createdAt,
                                   boolean expired) {
    public static NotificationResponse from(Notification n, LocalDateTime now) {
        return new NotificationResponse(n.getId(), n.getTitle(), n.getBody(), n.getRouteId(),
                n.getExpiresAt(), n.getCreatedAt(), n.isExpired(now));
    }
}
