package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.UUID;

public interface LinkInstitutionRouteUseCase {
    /// routeId nulo desvincula. Instituição já ligada a outra rota ATIVA gera conflito (RN15).
    Institution linkToRoute(UUID institutionId, UUID routeId);
}
