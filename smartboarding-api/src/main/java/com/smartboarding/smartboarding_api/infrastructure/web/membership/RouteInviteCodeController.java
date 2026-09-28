package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
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
import java.util.Set;
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
    private final RouteRepositoryPort routeRepository;
    private final AdminGuard guard;
    private final Clock clock;

    public RouteInviteCodeController(ManageRouteInviteCodeUseCase useCase,
                                     UserRepositoryPort userRepository,
                                     InstitutionRepositoryPort institutionRepository,
                                     RouteRepositoryPort routeRepository,
                                     AdminGuard guard,
                                     Clock clock) {
        this.useCase = useCase;
        this.userRepository = userRepository;
        this.institutionRepository = institutionRepository;
        this.routeRepository = routeRepository;
        this.guard = guard;
        this.clock = clock;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteInviteCodeResponse>>> list(
            @PathVariable UUID routeId, Authentication auth) {
        UUID admin = guard.id(auth);
        guard.ownsRoute(auth, routeId);
        Set<UUID> minhas = guard.institutions(auth);
        LocalDateTime now = LocalDateTime.now(clock);
        // Nomes resolvidos de uma vez: buscar por codigo faria uma consulta por
        // linha da lista pra escrever o mesmo punhado de nomes.
        Map<UUID, String> nomes = institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));
        List<RouteInviteCodeResponse> codes = useCase.listByRoute(routeId).stream()
                // Codigo de instituicao alheia nao aparece: ver o codigo ja e
                // poder distribui-lo. Aberto (nulo) aparece pra todo admin da
                // rota, porque nao e de ninguem.
                .filter(c -> c.getInstitutionId() == null
                        || minhas.contains(c.getInstitutionId()))
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
        UUID admin = guard.id(auth);
        UUID instituicao = request == null ? null : request.institutionId();
        guard.ownsRoute(auth, routeId);
        guard.ownsInstitution(auth, instituicao);

        var code = useCase.generate(routeId,
                request == null ? null : request.expiresAt(),
                instituicao,
                admin);
        // Com o nome da rota: a tela de códigos agrupa por ela, e sem isso o
        // código recém-criado caía num grupo "Rota" solto em vez de aparecer
        // junto dos outros da mesma rota.
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                RouteInviteCodeResponse.from(
                        code, 0, LocalDateTime.now(clock),
                        nomeDa(code.getInstitutionId()), nomeDaRota(routeId))));
    }

    @DeleteMapping("/{codeId}")
    public ResponseEntity<ApiResponse<RouteInviteCodeResponse>> revoke(@PathVariable UUID routeId,
                                                                       @PathVariable UUID codeId,
                                                                       Authentication auth) {
        UUID admin = guard.id(auth);
        guard.ownsRoute(auth, routeId);
        // A instituicao dona vem do codigo, nao do pedido: conferir o que o
        // cliente mandou deixaria ele escolher a resposta da propria checagem.
        guard.ownsInstitution(auth, useCase.findById(codeId).getInstitutionId());

        var code = useCase.revoke(codeId);
        return ResponseEntity.ok(ApiResponse.data(RouteInviteCodeResponse.from(
                code, useCase.countUses(codeId), LocalDateTime.now(clock),
                nomeDa(code.getInstitutionId()))));
    }

    private String nomeDaRota(UUID routeId) {
        return routeRepository.findById(routeId).map(Route::getName).orElse(null);
    }

    private String nomeDa(UUID institutionId) {
        if (institutionId == null) return null;
        return institutionRepository.findById(institutionId)
                .map(Institution::getName)
                .orElse(null);
    }

}
