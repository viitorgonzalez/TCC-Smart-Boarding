package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateStopRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 150) String name,
        Double latitude,
        Double longitude,
        Integer sequence,
        UUID institutionId,
        Boolean mainPoint
) {
    public boolean isMainPoint() {
        return Boolean.TRUE.equals(mainPoint);
    }
}
