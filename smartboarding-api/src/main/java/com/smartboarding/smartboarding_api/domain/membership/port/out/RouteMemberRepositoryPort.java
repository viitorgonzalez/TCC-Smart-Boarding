package com.smartboarding.smartboarding_api.domain.membership.port.out;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;

import java.util.List;
import java.util.UUID;

public interface RouteMemberRepositoryPort {
    RouteMember save(RouteMember member);

    List<RouteMember> findAllByUserId(UUID userId);

    List<RouteMember> findAllByRouteId(UUID routeId);

    boolean existsByUserIdAndRouteId(UUID userId, UUID routeId);

    void deleteByUserIdAndRouteId(UUID userId, UUID routeId);

    long countByInviteCodeId(UUID inviteCodeId);
}
