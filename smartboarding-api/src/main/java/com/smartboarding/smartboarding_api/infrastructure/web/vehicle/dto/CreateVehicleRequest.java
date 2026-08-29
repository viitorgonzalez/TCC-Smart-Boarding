package com.smartboarding.smartboarding_api.infrastructure.web.vehicle.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record CreateVehicleRequest(
        @NotBlank(message = "label can't be empty") @Size(max = 100) String label,
        @NotNull @Positive Integer capacity
) {}
