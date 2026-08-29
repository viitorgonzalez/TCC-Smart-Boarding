package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RejectRegistrationRequest(
        @NotBlank(message = "reason can't be empty")
        @Size(max = 500, message = "reason is too long")
        String reason
) {}
