package com.smartboarding.smartboarding_api.infrastructure.web.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.CreateRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.DeleteRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.FindRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteScheduleUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.route.dto.CreateRouteRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.route.dto.RouteResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.route.dto.UpdateRouteRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.route.dto.UpdateScheduleRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/routes")
public class RouteController {

    private final CreateRouteUseCase createRouteUseCase;
    private final FindRouteUseCase findRouteUseCase;
    private final UpdateRouteUseCase updateRouteUseCase;
    private final DeleteRouteUseCase deleteRouteUseCase;
    private final UpdateRouteScheduleUseCase updateRouteScheduleUseCase;

    public RouteController(CreateRouteUseCase createRouteUseCase,
                           FindRouteUseCase findRouteUseCase,
                           UpdateRouteUseCase updateRouteUseCase,
                           DeleteRouteUseCase deleteRouteUseCase,
                           UpdateRouteScheduleUseCase updateRouteScheduleUseCase) {
        this.createRouteUseCase = createRouteUseCase;
        this.findRouteUseCase = findRouteUseCase;
        this.updateRouteUseCase = updateRouteUseCase;
        this.deleteRouteUseCase = deleteRouteUseCase;
        this.updateRouteScheduleUseCase = updateRouteScheduleUseCase;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RouteResponse>> create(@RequestBody @Valid CreateRouteRequest request) {
        Route route = Route.builder().name(request.name()).description(request.description())
                .openTime(request.openTime()).closeTime(request.closeTime()).build();
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(RouteResponse.from(createRouteUseCase.execute(route))));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteResponse>>> findAll() {
        List<RouteResponse> routes = findRouteUseCase.findAllActive().stream().map(RouteResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(routes));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RouteResponse>> findById(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.data(RouteResponse.from(findRouteUseCase.findById(id))));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<RouteResponse>> update(@PathVariable UUID id,
                                                             @RequestBody @Valid UpdateRouteRequest request) {
        Route route = Route.builder().name(request.name()).description(request.description()).build();
        return ResponseEntity.ok(ApiResponse.data(RouteResponse.from(updateRouteUseCase.execute(id, route, request.isActive()))));
    }

    @PatchMapping("/{id}/schedule")
    public ResponseEntity<ApiResponse<RouteResponse>> updateSchedule(
            @PathVariable UUID id, @RequestBody @Valid UpdateScheduleRequest request) {
        Route saved = updateRouteScheduleUseCase.execute(
                id, request.openTime(), request.closeTime(), request.reason());
        return ResponseEntity.ok(ApiResponse.data(RouteResponse.from(saved)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID id) {
        deleteRouteUseCase.execute(id);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
