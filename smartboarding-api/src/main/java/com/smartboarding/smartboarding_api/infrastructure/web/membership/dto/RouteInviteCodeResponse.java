package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.time.LocalDateTime;
import java.util.UUID;

/// [uses] conta quantos alunos entraram por este código — é o que o admin usa
/// pra saber se o código circulou ou se ninguém recebeu.
public record RouteInviteCodeResponse(UUID id, UUID routeId, String code,
                                      LocalDateTime expiresAt, LocalDateTime revokedAt,
                                      boolean usable, long uses) {

    public static RouteInviteCodeResponse from(RouteInviteCode code, long uses, LocalDateTime now) {
        return new RouteInviteCodeResponse(
                code.getId(), code.getRouteId(), code.getCode(),
                code.getExpiresAt(), code.getRevokedAt(),
                code.isUsable(now), uses);
    }
}
