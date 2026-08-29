package com.smartboarding.smartboarding_api.infrastructure.web.vehicle;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import com.smartboarding.smartboarding_api.domain.vehicle.port.in.ManageVehiclesUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.vehicle.dto.CreateVehicleRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.vehicle.dto.VehicleResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/routes/{routeId}/vehicles")
public class VehicleController {

    private final ManageVehiclesUseCase manageVehiclesUseCase;

    public VehicleController(ManageVehiclesUseCase manageVehiclesUseCase) {
        this.manageVehiclesUseCase = manageVehiclesUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> list(@PathVariable UUID routeId) {
        List<VehicleResponse> vehicles = manageVehiclesUseCase.listByRoute(routeId).stream()
                .map(VehicleResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(vehicles));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<VehicleResponse>> create(@PathVariable UUID routeId,
                                                               @RequestBody @Valid CreateVehicleRequest request) {
        Vehicle vehicle = Vehicle.builder()
                .routeId(routeId).label(request.label()).capacity(request.capacity())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(VehicleResponse.from(manageVehiclesUseCase.add(vehicle))));
    }

    @DeleteMapping("/{vehicleId}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID routeId, @PathVariable UUID vehicleId) {
        manageVehiclesUseCase.remove(vehicleId);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
