package com.smartboarding.smartboarding_api.infrastructure.web.stop;

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

    public StopController(ManageStopsUseCase manageStopsUseCase) {
        this.manageStopsUseCase = manageStopsUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<StopResponse>>> list(@PathVariable UUID routeId) {
        List<StopResponse> stops = manageStopsUseCase.listByRoute(routeId).stream()
                .map(StopResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(stops));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<StopResponse>> create(@PathVariable UUID routeId,
                                                            @RequestBody @Valid CreateStopRequest request) {
        Stop stop = Stop.builder()
                .routeId(routeId).name(request.name())
                .latitude(request.latitude()).longitude(request.longitude())
                .sequence(request.sequence() == null ? 0 : request.sequence())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(StopResponse.from(manageStopsUseCase.add(stop))));
    }

    @PatchMapping("/{stopId}")
    public ResponseEntity<ApiResponse<StopResponse>> update(@PathVariable UUID routeId,
                                                            @PathVariable UUID stopId,
                                                            @RequestBody @Valid UpdateStopRequest request) {
        return ResponseEntity.ok(ApiResponse.data(StopResponse.from(
                manageStopsUseCase.update(stopId, request.name(),
                        request.latitude(), request.longitude()))));
    }

    @DeleteMapping("/{stopId}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID routeId, @PathVariable UUID stopId) {
        manageStopsUseCase.remove(stopId);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
