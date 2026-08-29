package com.smartboarding.smartboarding_api.infrastructure.web.vehicle.dto;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;

import java.util.UUID;

public record VehicleResponse(UUID id, String label, int capacity) {
    public static VehicleResponse from(Vehicle vehicle) {
        return new VehicleResponse(vehicle.getId(), vehicle.getLabel(), vehicle.getCapacity());
    }
}
