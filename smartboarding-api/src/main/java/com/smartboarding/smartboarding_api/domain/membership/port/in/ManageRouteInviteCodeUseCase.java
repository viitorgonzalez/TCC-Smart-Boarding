package com.smartboarding.smartboarding_api.domain.membership.port.in;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface ManageRouteInviteCodeUseCase {
    RouteInviteCode generate(UUID routeId, LocalDateTime expiresAt,
                             UUID institutionId, UUID adminId);

    RouteInviteCode revoke(UUID codeId);

    RouteInviteCode findById(UUID codeId);

    List<RouteInviteCode> findAllById(List<UUID> codeIds);

    int archive(List<UUID> codeIds);

    List<RouteInviteCode> listByRoute(UUID routeId);

    long countUses(UUID codeId);
}
