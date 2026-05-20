package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateRouteRequest(
        @NotBlank(message = "name can't be empty") String name,
        String description
) {}
