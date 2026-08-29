package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import java.util.UUID;

/// routeId nulo desvincula a instituição da rota atual.
public record LinkRouteRequest(UUID routeId) {}
