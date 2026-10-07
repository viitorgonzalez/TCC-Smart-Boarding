package com.smartboarding.smartboarding_api.domain.route.port.in;

import java.util.UUID;

public interface RouteTimingUseCase {
    void recalculate(UUID routeId);

    void recalculateIfMissing(UUID routeId);
}
