package com.smartboarding.smartboarding_api.infrastructure.web.vehicle;

import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
import org.springframework.security.core.Authentication;

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
    private final AdminGuard guard;

    public VehicleController(ManageVehiclesUseCase manageVehiclesUseCase,
                            AdminGuard guard) {
        this.manageVehiclesUseCase = manageVehiclesUseCase;
        this.guard = guard;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> list(@PathVariable UUID routeId,
                                                                   Authentication auth) {
        guard.ownsRoute(auth, routeId);
        List<VehicleResponse> vehicles = manageVehiclesUseCase.listByRoute(routeId).stream()
                .map(VehicleResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(vehicles));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<VehicleResponse>> create(@PathVariable UUID routeId,
                                                               @RequestBody @Valid CreateVehicleRequest request,
                                                               Authentication auth) {
        guard.ownsRoute(auth, routeId);
        Vehicle vehicle = Vehicle.builder()
                .routeId(routeId).label(request.label()).capacity(request.capacity())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(VehicleResponse.from(manageVehiclesUseCase.add(vehicle))));
    }

    @DeleteMapping("/{vehicleId}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID routeId,
                                                 @PathVariable UUID vehicleId,
                                                 Authentication auth) {
        guard.ownsRoute(auth, routeId);
        manageVehiclesUseCase.remove(vehicleId);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
