package com.smartboarding.smartboarding_api.infrastructure.web.stop;

import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
import org.springframework.security.core.Authentication;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.stop.dto.CreateStopRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.stop.dto.StopResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.stop.dto.UpdateStopRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/routes/{routeId}/stops")
public class StopController {

    private final ManageStopsUseCase manageStopsUseCase;
    private final AdminGuard guard;

    public StopController(ManageStopsUseCase manageStopsUseCase,
                            AdminGuard guard) {
        this.manageStopsUseCase = manageStopsUseCase;
        this.guard = guard;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<StopResponse>>> list(@PathVariable UUID routeId) {
        List<StopResponse> stops = manageStopsUseCase.listByRoute(routeId).stream()
                .map(StopResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(stops));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<StopResponse>> create(@PathVariable UUID routeId,
                                                            @RequestBody @Valid CreateStopRequest request,
                                                            Authentication auth) {
        guard.ownsRoute(auth, routeId);
        Stop stop = Stop.builder()
                .routeId(routeId).name(request.name())
                .latitude(request.latitude()).longitude(request.longitude())
                .sequence(request.sequence() == null ? 0 : request.sequence())
                .institutionId(request.institutionId())
                .isMainPoint(request.isMainPoint())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(StopResponse.from(manageStopsUseCase.add(stop))));
    }

    @PatchMapping("/{stopId}")
    public ResponseEntity<ApiResponse<StopResponse>> update(@PathVariable UUID routeId,
                                                            @PathVariable UUID stopId,
                                                            @RequestBody @Valid UpdateStopRequest request,
                                                            Authentication auth) {
        guard.ownsRoute(auth, routeId);
        // Arrastar o pino no mapa manda só as coordenadas. Chamar a sobrecarga
        // completa aí passaria institutionId nulo junto e desvincularia a
        // instituição sem ninguém pedir.
        Stop salva = request.mexeNoVinculo()
                ? manageStopsUseCase.update(stopId, request.name(), request.latitude(),
                        request.longitude(), request.institutionId(), request.isMainPoint())
                : manageStopsUseCase.update(stopId, request.name(),
                        request.latitude(), request.longitude());
        return ResponseEntity.ok(ApiResponse.data(StopResponse.from(salva)));
    }

    @DeleteMapping("/{stopId}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID routeId,
                                                 @PathVariable UUID stopId,
                                                 Authentication auth) {
        guard.ownsRoute(auth, routeId);
        manageStopsUseCase.remove(stopId);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
