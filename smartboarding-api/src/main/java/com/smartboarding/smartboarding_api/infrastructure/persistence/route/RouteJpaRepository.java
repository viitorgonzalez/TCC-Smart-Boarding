package com.smartboarding.smartboarding_api.infrastructure.persistence.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RouteJpaRepository extends JpaRepository<Route, UUID> {
    List<Route> findAllByIsActiveTrue();
    boolean existsByName(String name);
    boolean existsByNameAndIdNot(String name, UUID id);
}
