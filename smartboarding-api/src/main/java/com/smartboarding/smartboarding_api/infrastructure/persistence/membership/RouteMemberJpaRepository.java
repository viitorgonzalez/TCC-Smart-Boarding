package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RouteMemberJpaRepository extends JpaRepository<RouteMember, UUID> {
    List<RouteMember> findAllByUserId(UUID userId);

    List<RouteMember> findAllByRouteId(UUID routeId);

    boolean existsByUserIdAndRouteId(UUID userId, UUID routeId);

    void deleteByUserIdAndRouteId(UUID userId, UUID routeId);

    long countByInviteCodeId(UUID inviteCodeId);
}
