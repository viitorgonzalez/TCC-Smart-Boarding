package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.membership.port.in.AdminScope;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ForbiddenException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
public class AdminScopeImpl implements AdminScope {

    private final UserInstitutionRepositoryPort userInstitutionRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final RouteRepositoryPort routeRepository;

    public AdminScopeImpl(UserInstitutionRepositoryPort userInstitutionRepository,
                          InstitutionRepositoryPort institutionRepository,
                          RouteRepositoryPort routeRepository) {
        this.userInstitutionRepository = userInstitutionRepository;
        this.institutionRepository = institutionRepository;
        this.routeRepository = routeRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public Set<UUID> institutionsOf(UUID adminId) {
        return userInstitutionRepository.findAllByUserId(adminId).stream()
                .map(UserInstitution::getInstitutionId)
                .collect(Collectors.toSet());
    }

    @Override
    @Transactional(readOnly = true)
    public Set<UUID> routesOf(UUID adminId) {
        var instituicoes = institutionRepository.findAll();
        Set<UUID> minhas = institutionsOf(adminId);

        Set<UUID> alcance = instituicoes.stream()
                .filter(i -> minhas.contains(i.getId()))
                .map(Institution::getRouteId)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(java.util.HashSet::new));

        // Rota sem instituição nenhuma fica visível a todo admin. É o estado de
        // uma rota recém-criada, e o vínculo com a instituição se faz DENTRO
        // dela: sem esta linha, quem criasse uma rota não conseguiria mais
        // abri-la pra vincular, e ela ficaria órfã pra sempre.
        Set<UUID> comDono = instituicoes.stream()
                .map(Institution::getRouteId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        routeRepository.findAllByIsActiveTrue().stream()
                .map(Route::getId)
                .filter(id -> !comDono.contains(id))
                .forEach(alcance::add);

        return Set.copyOf(alcance);
    }

    @Override
    @Transactional(readOnly = true)
    public void assertAdministersRoute(UUID adminId, UUID routeId) {
        if (routeId == null || !routesOf(adminId).contains(routeId)) {
            log.warn("Admin {} tentou agir na rota {}, fora do alcance dele", adminId, routeId);
            throw new ForbiddenException("NOT_YOUR_ROUTE",
                    "Essa rota não atende nenhuma instituição que você administra.");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public void assertAdministersInstitution(UUID adminId, UUID institutionId) {
        // Nulo e o codigo aberto: nao pertence a instituicao nenhuma, entao nao
        // ha dono pra conferir. Quem limita o alcance ai e a rota.
        if (institutionId == null) return;
        if (!institutionsOf(adminId).contains(institutionId)) {
            log.warn("Admin {} tentou agir na instituicao {}, fora do alcance dele",
                    adminId, institutionId);
            throw new ForbiddenException("NOT_YOUR_INSTITUTION",
                    "Você não administra essa instituição.");
        }
    }
}
