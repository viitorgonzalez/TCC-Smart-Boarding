package com.smartboarding.smartboarding_api.infrastructure.web.route;

import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
import com.smartboarding.smartboarding_api.shared.exception.ForbiddenException;
import org.springframework.security.core.Authentication;

import java.util.Set;

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
    private final AdminGuard guard;
    private final RouteMemberRepositoryPort memberRepository;

    public RouteController(CreateRouteUseCase createRouteUseCase,
                           FindRouteUseCase findRouteUseCase,
                           UpdateRouteUseCase updateRouteUseCase,
                           DeleteRouteUseCase deleteRouteUseCase,
                           UpdateRouteScheduleUseCase updateRouteScheduleUseCase,
                           AdminGuard guard,
                           RouteMemberRepositoryPort memberRepository) {
        this.createRouteUseCase = createRouteUseCase;
        this.findRouteUseCase = findRouteUseCase;
        this.updateRouteUseCase = updateRouteUseCase;
        this.deleteRouteUseCase = deleteRouteUseCase;
        this.updateRouteScheduleUseCase = updateRouteScheduleUseCase;
        this.guard = guard;
        this.memberRepository = memberRepository;
    }


    @PostMapping
    public ResponseEntity<ApiResponse<RouteResponse>> create(@RequestBody @Valid CreateRouteRequest request) {
        Route route = Route.builder().name(request.name()).description(request.description())
                .openTime(request.openTime()).closeTime(request.closeTime()).build();
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(RouteResponse.from(createRouteUseCase.execute(route))));
    }

    /// Só as rotas que o admin administra — as usadas pelas instituições que
    /// ele declarou no perfil. Devolver todas fazia ele abrir a lista, os
    /// veículos e os códigos de transporte que não é dele.
    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteResponse>>> findAll(Authentication auth) {
        Set<UUID> minhas = guard.routes(auth);
        List<RouteResponse> routes = findRouteUseCase.findAllActive().stream()
                .filter(r -> minhas.contains(r.getId()))
                .map(RouteResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(routes));
    }

    /// Aberto a quem tem a ver com a rota: o aluno que está nela e o admin que
    /// a administra. O aluno precisa dela pro mapa e pro horário, então exigir
    /// papel de admin aqui quebraria a tela dele.
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RouteResponse>> findById(@PathVariable UUID id,
                                                               Authentication auth) {
        UUID quem = guard.id(auth);
        if (!memberRepository.existsByUserIdAndRouteId(quem, id)
                && !guard.routes(auth).contains(id)) {
            throw new ForbiddenException("NOT_YOUR_ROUTE", "Essa rota não é sua.");
        }
        return ResponseEntity.ok(ApiResponse.data(RouteResponse.from(findRouteUseCase.findById(id))));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<RouteResponse>> update(@PathVariable UUID id,
                                                             @RequestBody @Valid UpdateRouteRequest request,
                                                             Authentication auth) {
        guard.ownsRoute(auth, id);
        Route route = Route.builder()
                .name(request.name())
                .description(request.description())
                .build();
        return ResponseEntity.ok(ApiResponse.data(RouteResponse.from(
                updateRouteUseCase.execute(id, route, request.isActive(),
                        request.admitsNoInstitution()))));
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
