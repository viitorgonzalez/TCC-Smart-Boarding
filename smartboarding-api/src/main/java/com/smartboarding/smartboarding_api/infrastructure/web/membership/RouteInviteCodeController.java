package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.membership.dto.GenerateCodeRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.membership.dto.RouteInviteCodeResponse;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/// Gestão do código de convite da rota. Tudo aqui é do admin — o aluno só usa o
/// código, pelo MembershipController.
@RestController
@RequestMapping("/api/routes/{routeId}/invite-codes")
public class RouteInviteCodeController {

    private final ManageRouteInviteCodeUseCase useCase;
    private final UserRepositoryPort userRepository;
    private final Clock clock;

    public RouteInviteCodeController(ManageRouteInviteCodeUseCase useCase,
                                     UserRepositoryPort userRepository,
                                     Clock clock) {
        this.useCase = useCase;
        this.userRepository = userRepository;
        this.clock = clock;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteInviteCodeResponse>>> list(@PathVariable UUID routeId) {
        LocalDateTime now = LocalDateTime.now(clock);
        List<RouteInviteCodeResponse> codes = useCase.listByRoute(routeId).stream()
                .map(c -> RouteInviteCodeResponse.from(c, useCase.countUses(c.getId()), now))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(codes));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RouteInviteCodeResponse>> generate(
            @PathVariable UUID routeId,
            @RequestBody(required = false) @Valid GenerateCodeRequest request,
            Authentication auth) {
        var code = useCase.generate(routeId,
                request == null ? null : request.expiresAt(), adminId(auth));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                RouteInviteCodeResponse.from(code, 0, LocalDateTime.now(clock))));
    }

    @DeleteMapping("/{codeId}")
    public ResponseEntity<ApiResponse<RouteInviteCodeResponse>> revoke(@PathVariable UUID routeId,
                                                                       @PathVariable UUID codeId) {
        var code = useCase.revoke(codeId);
        return ResponseEntity.ok(ApiResponse.data(RouteInviteCodeResponse.from(
                code, useCase.countUses(codeId), LocalDateTime.now(clock))));
    }

    private UUID adminId(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
