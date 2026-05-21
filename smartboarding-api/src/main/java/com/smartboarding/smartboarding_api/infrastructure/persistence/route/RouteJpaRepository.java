package com.smartboarding.smartboarding_api.infrastructure.persistence.route;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface RouteJpaRepository extends JpaRepository<RouteJpaEntity, UUID> {
    List<RouteJpaEntity> findAllByIsActiveTrue();
    boolean existsByName(String name);
    boolean existsByNameAndIdNot(String name, UUID id);
}
