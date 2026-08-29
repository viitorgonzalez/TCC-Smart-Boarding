package com.smartboarding.smartboarding_api.domain.vehicle.port.in;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;

import java.util.List;
import java.util.UUID;

public interface ManageVehiclesUseCase {
    List<Vehicle> listByRoute(UUID routeId);
    Vehicle add(Vehicle vehicle);
    void remove(UUID vehicleId);
}
