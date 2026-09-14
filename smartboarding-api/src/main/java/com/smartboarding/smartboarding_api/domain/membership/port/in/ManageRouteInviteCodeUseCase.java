package com.smartboarding.smartboarding_api.domain.membership.port.in;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface ManageRouteInviteCodeUseCase {
    /// [expiresAt] nulo usa a validade padrão da configuração.
    RouteInviteCode generate(UUID routeId, LocalDateTime expiresAt, UUID adminId);

    RouteInviteCode revoke(UUID codeId);

    List<RouteInviteCode> listByRoute(UUID routeId);

    long countUses(UUID codeId);
}
