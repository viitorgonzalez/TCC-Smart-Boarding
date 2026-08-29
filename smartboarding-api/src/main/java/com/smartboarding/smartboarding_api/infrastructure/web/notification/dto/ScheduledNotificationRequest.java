package com.smartboarding.smartboarding_api.infrastructure.web.notification.dto;

import com.smartboarding.smartboarding_api.domain.notification.entity.NotificationFrequency;
import jakarta.validation.constraints.*;

import java.time.LocalTime;
import java.util.UUID;

public record ScheduledNotificationRequest(
        @NotNull UUID routeId,
        @NotBlank @Size(max = 150) String title,
        @NotBlank String body,
        @NotNull NotificationFrequency frequency,
        @NotNull LocalTime sendAt,
        /// Só para WEEKLY: 1=segunda … 7=domingo.
        @Min(1) @Max(7) Integer dayOfWeek,
        @Positive Integer durationHours
) {}
