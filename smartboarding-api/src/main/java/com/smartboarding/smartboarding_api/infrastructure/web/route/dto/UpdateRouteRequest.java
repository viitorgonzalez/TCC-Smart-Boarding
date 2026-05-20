package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateRouteRequest(
        @NotBlank(message = "name can't be empty") String name,
        String description
) {}
