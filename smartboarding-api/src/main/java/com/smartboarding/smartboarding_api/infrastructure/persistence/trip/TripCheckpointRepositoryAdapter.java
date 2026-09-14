package com.smartboarding.smartboarding_api.infrastructure.persistence.trip;

import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class TripCheckpointRepositoryAdapter implements TripCheckpointRepositoryPort {

    private final TripCheckpointJpaRepository jpaRepository;

    public TripCheckpointRepositoryAdapter(TripCheckpointJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public TripCheckpoint save(TripCheckpoint checkpoint) {
        return jpaRepository.save(checkpoint);
    }

    @Override
    public List<TripCheckpoint> findAllByDailyListId(UUID dailyListId) {
        return jpaRepository.findAllByDailyListIdOrderByReachedAtAsc(dailyListId);
    }

    @Override
    public boolean existsByDailyListIdAndStopIdAndLeg(UUID dailyListId, UUID stopId,
            com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg leg) {
        return jpaRepository.existsByDailyListIdAndStopIdAndLeg(dailyListId, stopId, leg);
    }
}
