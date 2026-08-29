package com.smartboarding.smartboarding_api.infrastructure.web.notification.dto;

import com.smartboarding.smartboarding_api.domain.notification.entity.NotificationFrequency;
import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

public record ScheduledNotificationResponse(UUID id, UUID routeId, String title, String body,
                                            NotificationFrequency frequency, LocalTime sendAt,
                                            Integer dayOfWeek, Integer durationHours,
                                            boolean active, LocalDateTime lastSentAt) {
    public static ScheduledNotificationResponse from(ScheduledNotification n) {
        return new ScheduledNotificationResponse(n.getId(), n.getRouteId(), n.getTitle(),
                n.getBody(), n.getFrequency(), n.getSendAt(), n.getDayOfWeek(),
                n.getDurationHours(), n.isActive(), n.getLastSentAt());
    }
}
