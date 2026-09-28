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

    List<RouteInviteCode> findAllById(List<UUID> codeIds);

    /// Tira os códigos da tela do admin sem apagar o registro — quem entrou por
    /// eles mantém a origem no relatório.
    ///
    /// Devolve quantos foram arquivados de fato: arquivar de novo não é erro, o
    /// admin pode repetir o gesto e o resultado que ele quer já está valendo.
    int archive(List<UUID> codeIds);

    List<RouteInviteCode> listByRoute(UUID routeId);

    long countUses(UUID codeId);
}
