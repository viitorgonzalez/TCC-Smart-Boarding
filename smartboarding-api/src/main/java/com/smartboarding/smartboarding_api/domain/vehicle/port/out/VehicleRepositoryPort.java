package com.smartboarding.smartboarding_api.domain.vehicle.port.out;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;

import java.util.List;
import java.util.UUID;

public interface VehicleRepositoryPort {
    Vehicle save(Vehicle vehicle);
    List<Vehicle> findAllByRouteId(UUID routeId);
    int totalCapacityByRouteId(UUID routeId);
    void deleteById(UUID id);
}
