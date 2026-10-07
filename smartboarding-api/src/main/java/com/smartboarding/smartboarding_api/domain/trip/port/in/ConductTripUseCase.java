package com.smartboarding.smartboarding_api.domain.trip.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;

import java.util.UUID;

public interface ConductTripUseCase {
    DailyList start(UUID listId);

    DailyList checkpoint(UUID listId, UUID stopId);

    DailyList finish(UUID listId);
}
