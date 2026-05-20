package com.smartboarding.smartboarding_api.infrastructure.web.notification.dto;

import jakarta.validation.constraints.NotBlank;

public record BroadcastRequest(
        @NotBlank(message = "title can't be empty") String title,
        @NotBlank(message = "body can't be empty") String body
) {}
