package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RejectProfileUpdateRequest(
        @NotBlank(message = "explique o motivo") @Size(max = 500) String reason
) {}
