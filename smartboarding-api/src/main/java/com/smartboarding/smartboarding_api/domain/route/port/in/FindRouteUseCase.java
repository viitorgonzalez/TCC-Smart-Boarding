package com.smartboarding.smartboarding_api.domain.route.port.in;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.util.List;
import java.util.UUID;

public interface FindRouteUseCase {
    List<Route> findAllActive();
    Route findById(UUID id);
}
