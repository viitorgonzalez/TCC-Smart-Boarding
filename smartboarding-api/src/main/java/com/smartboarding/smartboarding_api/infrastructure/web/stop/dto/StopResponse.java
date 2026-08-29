package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;

import java.util.UUID;

public record StopResponse(UUID id, String name, Double latitude, Double longitude, int sequence) {
    public static StopResponse from(Stop stop) {
        return new StopResponse(stop.getId(), stop.getName(), stop.getLatitude(),
                stop.getLongitude(), stop.getSequence());
    }
}
