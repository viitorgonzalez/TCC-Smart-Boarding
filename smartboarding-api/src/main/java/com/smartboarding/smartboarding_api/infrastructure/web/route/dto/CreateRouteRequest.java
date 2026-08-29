package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalTime;

public record CreateRouteRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 100) String name,
        @Size(max = 255) String description,
        LocalTime openTime,
        LocalTime closeTime
) {}
