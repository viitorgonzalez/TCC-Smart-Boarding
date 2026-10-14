package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateStopRequest(
        @Size(max = 150) String name,
        Double latitude,
        Double longitude,
        UUID institutionId,
        Boolean mainPoint
) {
    public boolean mexeNoVinculo() {
        return institutionId != null || mainPoint != null;
    }

    public boolean isMainPoint() {
        return Boolean.TRUE.equals(mainPoint);
    }
}
