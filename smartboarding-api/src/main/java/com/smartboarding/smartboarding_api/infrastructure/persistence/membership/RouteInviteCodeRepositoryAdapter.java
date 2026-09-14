package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class RouteInviteCodeRepositoryAdapter implements RouteInviteCodeRepositoryPort {

    private final RouteInviteCodeJpaRepository jpa;

    public RouteInviteCodeRepositoryAdapter(RouteInviteCodeJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public RouteInviteCode save(RouteInviteCode code) { return jpa.save(code); }
    @Override public Optional<RouteInviteCode> findByCode(String code) { return jpa.findByCode(code); }
    @Override public Optional<RouteInviteCode> findById(UUID id) { return jpa.findById(id); }
    @Override public boolean existsByCode(String code) { return jpa.existsByCode(code); }
    @Override public List<RouteInviteCode> findAllByRouteId(UUID routeId) {
        return jpa.findAllByRouteIdOrderByCreatedAtDesc(routeId);
    }
}
