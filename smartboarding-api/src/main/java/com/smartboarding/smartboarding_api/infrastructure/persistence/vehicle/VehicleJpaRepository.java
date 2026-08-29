package com.smartboarding.smartboarding_api.infrastructure.persistence.vehicle;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface VehicleJpaRepository extends JpaRepository<Vehicle, UUID> {
    List<Vehicle> findAllByRouteId(UUID routeId);

    @Query("SELECT COALESCE(SUM(v.capacity), 0) FROM Vehicle v WHERE v.routeId = :routeId")
    int totalCapacityByRouteId(@Param("routeId") UUID routeId);
}
