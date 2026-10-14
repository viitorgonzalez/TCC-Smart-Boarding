package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.time.LocalDateTime;
import java.util.UUID;

public record RouteInviteCodeResponse(UUID id, UUID routeId, String routeName, String code,
                                      LocalDateTime expiresAt, LocalDateTime revokedAt,
                                      boolean usable, long uses,
                                      UUID institutionId, String institutionName) {

    public static RouteInviteCodeResponse from(RouteInviteCode code, long uses,
                                               LocalDateTime now, String institutionName) {
        return from(code, uses, now, institutionName, null);
    }

    public static RouteInviteCodeResponse from(RouteInviteCode code, long uses,
                                               LocalDateTime now, String institutionName,
                                               String routeName) {
        return new RouteInviteCodeResponse(
                code.getId(), code.getRouteId(), routeName, code.getCode(),
                code.getExpiresAt(), code.getRevokedAt(),
                code.isUsable(now), uses,
                code.getInstitutionId(), institutionName);
    }
}
