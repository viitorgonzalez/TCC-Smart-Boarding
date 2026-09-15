package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
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
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/// Gestão do código de convite da rota. Tudo aqui é do admin — o aluno só usa o
/// código, pelo MembershipController.
@RestController
@RequestMapping("/api/routes/{routeId}/invite-codes")
public class RouteInviteCodeController {

    private final ManageRouteInviteCodeUseCase useCase;
    private final UserRepositoryPort userRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final Clock clock;

    public RouteInviteCodeController(ManageRouteInviteCodeUseCase useCase,
                                     UserRepositoryPort userRepository,
                                     InstitutionRepositoryPort institutionRepository,
                                     Clock clock) {
        this.useCase = useCase;
        this.userRepository = userRepository;
        this.institutionRepository = institutionRepository;
        this.clock = clock;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteInviteCodeResponse>>> list(@PathVariable UUID routeId) {
        LocalDateTime now = LocalDateTime.now(clock);
        // Nomes resolvidos de uma vez: buscar por codigo faria uma consulta por
        // linha da lista pra escrever o mesmo punhado de nomes.
        Map<UUID, String> nomes = institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));
        List<RouteInviteCodeResponse> codes = useCase.listByRoute(routeId).stream()
                .map(c -> RouteInviteCodeResponse.from(
                        c, useCase.countUses(c.getId()), now, nomes.get(c.getInstitutionId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(codes));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RouteInviteCodeResponse>> generate(
            @PathVariable UUID routeId,
            @RequestBody(required = false) @Valid GenerateCodeRequest request,
            Authentication auth) {
        var code = useCase.generate(routeId,
                request == null ? null : request.expiresAt(),
                request == null ? null : request.institutionId(),
                adminId(auth));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                RouteInviteCodeResponse.from(
                        code, 0, LocalDateTime.now(clock), nomeDa(code.getInstitutionId()))));
    }

    @DeleteMapping("/{codeId}")
    public ResponseEntity<ApiResponse<RouteInviteCodeResponse>> revoke(@PathVariable UUID routeId,
                                                                       @PathVariable UUID codeId) {
        var code = useCase.revoke(codeId);
        return ResponseEntity.ok(ApiResponse.data(RouteInviteCodeResponse.from(
                code, useCase.countUses(codeId), LocalDateTime.now(clock),
                nomeDa(code.getInstitutionId()))));
    }

    private String nomeDa(UUID institutionId) {
        if (institutionId == null) return null;
        return institutionRepository.findById(institutionId)
                .map(Institution::getName)
                .orElse(null);
    }

    private UUID adminId(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
