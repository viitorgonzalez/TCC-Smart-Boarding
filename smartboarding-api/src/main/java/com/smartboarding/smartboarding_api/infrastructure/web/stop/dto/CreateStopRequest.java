package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateStopRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 150) String name,
        Double latitude,
        Double longitude,
        Integer sequence
) {}
