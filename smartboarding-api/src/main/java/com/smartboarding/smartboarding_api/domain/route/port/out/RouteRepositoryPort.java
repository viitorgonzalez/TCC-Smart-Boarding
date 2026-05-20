package com.smartboarding.smartboarding_api.domain.route.port.out;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RouteRepositoryPort {
    Route save(Route route);
    Optional<Route> findById(UUID id);
    List<Route> findAllByIsActiveTrue();
    boolean existsByName(String name);
    boolean existsByNameAndIdNot(String name, UUID id);
}
