package com.smartboarding.smartboarding_api.domain.membership.port.in;

import java.util.Set;
import java.util.UUID;

/// O alcance de um administrador: as instituições que ele declarou no perfil e
/// as rotas que elas usam.
///
/// Existe porque papel não é alcance. `ADMIN` diz o que a pessoa sabe fazer;
/// isto diz sobre o que ela pode fazer. Sem essa separação, quem administra o
/// IFMG revoga código da UNIFOR — o que acontecia antes desta interface.
public interface AdminScope {

    Set<UUID> institutionsOf(UUID adminId);

    /// Rotas usadas pelas instituições do admin. Derivado, não guardado: uma
    /// segunda fonte da verdade sairia de sincronia com `institutions.route_id`.
    Set<UUID> routesOf(UUID adminId);

    /// Lança ForbiddenException se a rota não for de nenhuma instituição dele.
    void assertAdministersRoute(UUID adminId, UUID routeId);

    /// Lança ForbiddenException se a instituição não for dele. `null` passa:
    /// é a escolha deliberada de código aberto, que não pertence a ninguém.
    void assertAdministersInstitution(UUID adminId, UUID institutionId);
}
