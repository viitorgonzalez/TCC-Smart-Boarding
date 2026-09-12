package com.smartboarding.smartboarding_api.infrastructure.persistence.trip;

import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TripCheckpointJpaRepository extends JpaRepository<TripCheckpoint, UUID> {
    List<TripCheckpoint> findAllByDailyListIdOrderByReachedAtAsc(UUID dailyListId);

    boolean existsByDailyListIdAndStopIdAndLeg(UUID dailyListId, UUID stopId,
            com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg leg);
}
