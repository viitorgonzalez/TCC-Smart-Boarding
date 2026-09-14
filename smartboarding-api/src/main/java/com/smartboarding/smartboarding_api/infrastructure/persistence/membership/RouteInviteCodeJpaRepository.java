package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RouteInviteCodeJpaRepository extends JpaRepository<RouteInviteCode, UUID> {
    Optional<RouteInviteCode> findByCode(String code);

    List<RouteInviteCode> findAllByRouteIdOrderByCreatedAtDesc(UUID routeId);

    boolean existsByCode(String code);
}
