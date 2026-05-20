package com.smartboarding.smartboarding_api.domain.route.port.in;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

public interface CreateRouteUseCase {
    Route execute(Route route);
}
