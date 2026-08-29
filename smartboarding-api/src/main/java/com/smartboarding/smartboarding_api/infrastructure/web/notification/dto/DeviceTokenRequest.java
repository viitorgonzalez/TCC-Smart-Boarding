package com.smartboarding.smartboarding_api.infrastructure.web.notification.dto;

import jakarta.validation.constraints.NotBlank;

public record DeviceTokenRequest(
        @NotBlank(message = "token can't be empty") String token,
        @NotBlank(message = "platform can't be empty") String platform
) {}
