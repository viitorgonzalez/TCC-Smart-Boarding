package com.smartboarding.smartboarding_api.domain.trip.port.out;

import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;

import java.util.List;
import java.util.UUID;

public interface TripCheckpointRepositoryPort {
    TripCheckpoint save(TripCheckpoint checkpoint);

    List<TripCheckpoint> findAllByDailyListId(UUID dailyListId);

    boolean existsByDailyListIdAndStopIdAndLeg(
            UUID dailyListId, UUID stopId,
            com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg leg);
}
