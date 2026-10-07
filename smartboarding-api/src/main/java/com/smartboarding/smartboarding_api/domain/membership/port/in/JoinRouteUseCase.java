package com.smartboarding.smartboarding_api.domain.membership.port.in;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;

import java.util.List;
import java.util.UUID;

public interface JoinRouteUseCase {
    RouteMember join(UUID userId, String code);

    void leave(UUID userId, UUID routeId);

    List<UUID> routesOf(UUID userId);
}
