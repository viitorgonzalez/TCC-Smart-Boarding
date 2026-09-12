package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.membership.port.in.JoinRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.FindRouteUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.membership.dto.JoinRouteRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.route.dto.RouteResponse;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/// As rotas do próprio usuário. O id sai do token: aceitar userId do request
/// deixaria um aluno entrar ou sair de rota em nome de outro.
@RestController
@RequestMapping("/api/me/routes")
public class MembershipController {

    private final JoinRouteUseCase joinRouteUseCase;
    private final FindRouteUseCase findRouteUseCase;
    private final UserRepositoryPort userRepository;

    public MembershipController(JoinRouteUseCase joinRouteUseCase,
                                FindRouteUseCase findRouteUseCase,
                                UserRepositoryPort userRepository) {
        this.joinRouteUseCase = joinRouteUseCase;
        this.findRouteUseCase = findRouteUseCase;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteResponse>>> myRoutes(Authentication auth) {
        List<RouteResponse> routes = joinRouteUseCase.routesOf(userId(auth)).stream()
                .map(findRouteUseCase::findById)
                .map(RouteResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(routes));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RouteResponse>> join(@RequestBody @Valid JoinRouteRequest request,
                                                            Authentication auth) {
        var member = joinRouteUseCase.join(userId(auth), request.code());
        Route route = findRouteUseCase.findById(member.getRouteId());
        return ResponseEntity.ok(ApiResponse.data(RouteResponse.from(route)));
    }

    @DeleteMapping("/{routeId}")
    public ResponseEntity<ApiResponse<?>> leave(@PathVariable UUID routeId, Authentication auth) {
        joinRouteUseCase.leave(userId(auth), routeId);
        return ResponseEntity.ok(ApiResponse.success());
    }

    private UUID userId(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
