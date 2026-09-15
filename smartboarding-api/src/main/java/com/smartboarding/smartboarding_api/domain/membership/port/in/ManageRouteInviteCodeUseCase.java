package com.smartboarding.smartboarding_api.domain.membership.port.in;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface ManageRouteInviteCodeUseCase {
    /// [expiresAt] nulo usa a validade padrão da configuração.
    /// [institutionId] nulo deixa o código aberto a qualquer instituição.
    RouteInviteCode generate(UUID routeId, LocalDateTime expiresAt,
                             UUID institutionId, UUID adminId);

    RouteInviteCode revoke(UUID codeId);

    /// Usado pela checagem de alcance antes de revogar: a instituição dona
    /// precisa vir do código guardado, não do pedido.
    RouteInviteCode findById(UUID codeId);

    List<RouteInviteCode> listByRoute(UUID routeId);

    long countUses(UUID codeId);
}
