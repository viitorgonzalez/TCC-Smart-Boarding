package com.smartboarding.smartboarding_api.infrastructure.persistence.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface StopJpaRepository extends JpaRepository<Stop, UUID> {
    List<Stop> findAllByRouteIdOrderBySequenceAsc(UUID routeId);
}
