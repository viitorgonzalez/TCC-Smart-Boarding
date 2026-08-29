package com.smartboarding.smartboarding_api.infrastructure.persistence.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public class StopRepositoryAdapter implements StopRepositoryPort {

    private final StopJpaRepository jpa;

    public StopRepositoryAdapter(StopJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public Stop save(Stop stop) { return jpa.save(stop); }
    @Override public java.util.Optional<Stop> findById(UUID id) { return jpa.findById(id); }
    @Override public void deleteById(UUID id) { jpa.deleteById(id); }
    @Override public List<Stop> findAllByRouteIdOrderBySequenceAsc(UUID routeId) {
        return jpa.findAllByRouteIdOrderBySequenceAsc(routeId);
    }
}
