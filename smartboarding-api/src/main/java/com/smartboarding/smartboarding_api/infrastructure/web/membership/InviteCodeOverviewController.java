package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
import com.smartboarding.smartboarding_api.infrastructure.web.membership.dto.RouteInviteCodeResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/// Os códigos de todas as rotas do admin, numa chamada só.
///
/// Existe porque a tela de códigos cruza rotas: montá-la pela rota exigiria uma
/// requisição por rota, e o app ainda teria que juntar tudo pra ordenar.
@RestController
@RequestMapping("/api/invite-codes")
public class InviteCodeOverviewController {

    private final ManageRouteInviteCodeUseCase useCase;
    private final RouteRepositoryPort routeRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final AdminGuard guard;
    private final Clock clock;

    public InviteCodeOverviewController(ManageRouteInviteCodeUseCase useCase,
                                        RouteRepositoryPort routeRepository,
                                        InstitutionRepositoryPort institutionRepository,
                                        AdminGuard guard,
                                        Clock clock) {
        this.useCase = useCase;
        this.routeRepository = routeRepository;
        this.institutionRepository = institutionRepository;
        this.guard = guard;
        this.clock = clock;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RouteInviteCodeResponse>>> list(Authentication auth) {
        Set<UUID> minhasRotas = guard.routes(auth);
        Set<UUID> minhasInstituicoes = guard.institutions(auth);
        LocalDateTime now = LocalDateTime.now(clock);

        Map<UUID, String> nomeDaRota = routeRepository.findAllByIsActiveTrue().stream()
                .filter(r -> minhasRotas.contains(r.getId()))
                .collect(Collectors.toMap(Route::getId, Route::getName));
        Map<UUID, String> nomeDaInstituicao = institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));

        List<RouteInviteCodeResponse> codes = nomeDaRota.keySet().stream()
                .flatMap(routeId -> useCase.listByRoute(routeId).stream())
                // Mesma regra da tela da rota: código de instituição alheia não
                // aparece, porque ver o código já é poder distribuí-lo.
                .filter(c -> c.getInstitutionId() == null
                        || minhasInstituicoes.contains(c.getInstitutionId()))
                .map(c -> RouteInviteCodeResponse.from(
                        c, useCase.countUses(c.getId()), now,
                        nomeDaInstituicao.get(c.getInstitutionId()),
                        nomeDaRota.get(c.getRouteId())))
                // Utilizável primeiro, e dentro disso o que vence antes: é a
                // ordem em que o admin decide se precisa gerar outro.
                .sorted(Comparator.comparing(RouteInviteCodeResponse::usable).reversed()
                        .thenComparing(RouteInviteCodeResponse::expiresAt,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();

        return ResponseEntity.ok(ApiResponse.data(codes));
    }
}
