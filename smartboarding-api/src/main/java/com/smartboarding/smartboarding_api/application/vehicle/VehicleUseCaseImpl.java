package com.smartboarding.smartboarding_api.application.vehicle;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import com.smartboarding.smartboarding_api.domain.vehicle.port.in.ManageVehiclesUseCase;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class VehicleUseCaseImpl implements ManageVehiclesUseCase {

    private final VehicleRepositoryPort vehicleRepository;

    public VehicleUseCaseImpl(VehicleRepositoryPort vehicleRepository) {
        this.vehicleRepository = vehicleRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Vehicle> listByRoute(UUID routeId) {
        return vehicleRepository.findAllByRouteId(routeId);
    }

    @Override
    @Transactional
    public Vehicle add(Vehicle vehicle) {
        return vehicleRepository.save(vehicle);
    }

    @Override
    @Transactional
    public void remove(UUID vehicleId) {
        vehicleRepository.deleteById(vehicleId);
    }
}
