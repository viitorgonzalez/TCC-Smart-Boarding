package com.smartboarding.smartboarding_api.infrastructure.persistence.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class RouteRepositoryAdapter implements RouteRepositoryPort {

    private final RouteJpaRepository jpa;

    public RouteRepositoryAdapter(RouteJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Route save(Route route) {
        return RouteMapper.toDomain(jpa.save(RouteMapper.toJpa(route)));
    }

    @Override
    public Optional<Route> findById(UUID id) {
        return jpa.findById(id).map(RouteMapper::toDomain);
    }

    @Override
    public List<Route> findAllByIsActiveTrue() {
        return jpa.findAllByIsActiveTrue().stream().map(RouteMapper::toDomain).toList();
    }

    @Override
    public boolean existsByName(String name) {
        return jpa.existsByName(name);
    }

    @Override
    public boolean existsByNameAndIdNot(String name, UUID id) {
        return jpa.existsByNameAndIdNot(name, id);
    }
}
