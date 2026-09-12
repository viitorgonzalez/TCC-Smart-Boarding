package com.smartboarding.smartboarding_api.domain.trip.port.out;

import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;

import java.util.List;
import java.util.UUID;

public interface TripCheckpointRepositoryPort {
    TripCheckpoint save(TripCheckpoint checkpoint);

    List<TripCheckpoint> findAllByDailyListId(UUID dailyListId);

    /// A mesma parada e visitada nas duas pernas, entao a checagem de repeticao
    /// precisa considerar qual perna -- senao o primeiro checkpoint da volta
    /// seria tratado como repeticao da ida e ignorado em silencio.
    boolean existsByDailyListIdAndStopIdAndLeg(
            UUID dailyListId, UUID stopId,
            com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg leg);
}
