package com.smartboarding.smartboarding_api.domain.membership.port.in;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;

import java.util.List;
import java.util.UUID;

public interface JoinRouteUseCase {
    /// Entra na rota do código. O código basta — não há aprovação depois.
    RouteMember join(UUID userId, String code);

    void leave(UUID userId, UUID routeId);

    List<UUID> routesOf(UUID userId);
}
