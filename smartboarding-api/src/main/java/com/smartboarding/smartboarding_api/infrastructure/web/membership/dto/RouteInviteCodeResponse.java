package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.time.LocalDateTime;
import java.util.UUID;

/// [uses] conta quantos alunos entraram por este código — é o que o admin usa
/// pra saber se o código circulou ou se ninguém recebeu.
///
/// [institutionName] vem junto do id porque a tela do admin lista códigos de
/// várias instituições ao mesmo tempo: só o id obrigaria o app a cruzar cada
/// código com o catálogo pra escrever uma linha.
public record RouteInviteCodeResponse(UUID id, UUID routeId, String routeName, String code,
                                      LocalDateTime expiresAt, LocalDateTime revokedAt,
                                      boolean usable, long uses,
                                      UUID institutionId, String institutionName) {

    public static RouteInviteCodeResponse from(RouteInviteCode code, long uses,
                                               LocalDateTime now, String institutionName) {
        return from(code, uses, now, institutionName, null);
    }

    /// [routeName] só é preenchido na listagem que cruza rotas — dentro de uma
    /// rota só, repetir o nome em cada linha seria ruído.
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
