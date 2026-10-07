package com.smartboarding.smartboarding_api.domain.stop.port.in;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;

import java.util.List;
import java.util.UUID;

public interface ManageStopsUseCase {
    List<Stop> listByRoute(UUID routeId);

    Stop add(Stop stop);

    Stop update(UUID stopId, String name, Double latitude, Double longitude);

    Stop update(UUID stopId, String name, Double latitude, Double longitude,
                UUID institutionId, boolean mainPoint);

    void remove(UUID stopId);
}
