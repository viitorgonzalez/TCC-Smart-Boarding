package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.UUID;

public interface LinkInstitutionRouteUseCase {
    Institution linkToRoute(UUID institutionId, UUID routeId);
}
