package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateRouteRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 100) String name,
        @Size(max = 255) String description,
        Boolean isActive,
        Boolean admitsNoInstitution
) {}
