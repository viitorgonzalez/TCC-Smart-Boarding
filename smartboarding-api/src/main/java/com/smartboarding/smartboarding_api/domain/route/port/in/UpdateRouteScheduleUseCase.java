package com.smartboarding.smartboarding_api.domain.route.port.in;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.time.LocalTime;
import java.util.UUID;

public interface UpdateRouteScheduleUseCase {

    Route execute(UUID routeId, LocalTime openTime, LocalTime closeTime, String reason);
}
