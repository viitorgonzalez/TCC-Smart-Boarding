package com.smartboarding.smartboarding_api.infrastructure.persistence.vehicle;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public class VehicleRepositoryAdapter implements VehicleRepositoryPort {

    private final VehicleJpaRepository jpa;

    public VehicleRepositoryAdapter(VehicleJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public Vehicle save(Vehicle vehicle) { return jpa.save(vehicle); }
    @Override public List<Vehicle> findAllByRouteId(UUID routeId) { return jpa.findAllByRouteId(routeId); }
    @Override public int totalCapacityByRouteId(UUID routeId) { return jpa.totalCapacityByRouteId(routeId); }
    @Override public void deleteById(UUID id) { jpa.deleteById(id); }
}
