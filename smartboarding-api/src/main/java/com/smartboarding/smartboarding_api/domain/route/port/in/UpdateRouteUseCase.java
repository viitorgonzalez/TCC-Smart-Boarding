package com.smartboarding.smartboarding_api.domain.route.port.in;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.util.UUID;

public interface UpdateRouteUseCase {
    Route execute(UUID id, Route route);
}
