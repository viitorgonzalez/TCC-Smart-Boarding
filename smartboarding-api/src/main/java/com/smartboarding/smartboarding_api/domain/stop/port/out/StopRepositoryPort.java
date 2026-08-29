package com.smartboarding.smartboarding_api.domain.stop.port.out;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;

import java.util.List;
import java.util.UUID;

public interface StopRepositoryPort {
    Stop save(Stop stop);
    java.util.Optional<Stop> findById(UUID id);
    List<Stop> findAllByRouteIdOrderBySequenceAsc(UUID routeId);
    void deleteById(UUID id);
}
