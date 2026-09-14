package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Repository
public class RouteMemberRepositoryAdapter implements RouteMemberRepositoryPort {

    private final RouteMemberJpaRepository jpa;

    public RouteMemberRepositoryAdapter(RouteMemberJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public RouteMember save(RouteMember member) { return jpa.save(member); }
    @Override public List<RouteMember> findAllByUserId(UUID userId) { return jpa.findAllByUserId(userId); }
    @Override public List<RouteMember> findAllByRouteId(UUID routeId) { return jpa.findAllByRouteId(routeId); }
    @Override public boolean existsByUserIdAndRouteId(UUID userId, UUID routeId) {
        return jpa.existsByUserIdAndRouteId(userId, routeId);
    }
    @Override public long countByInviteCodeId(UUID inviteCodeId) { return jpa.countByInviteCodeId(inviteCodeId); }

    @Override
    @Transactional
    public void deleteByUserIdAndRouteId(UUID userId, UUID routeId) {
        jpa.deleteByUserIdAndRouteId(userId, routeId);
    }
}
