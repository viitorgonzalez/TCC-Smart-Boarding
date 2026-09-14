package com.smartboarding.smartboarding_api.domain.passwordreset.port.out;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetRepositoryPort {

    PasswordResetRequest save(PasswordResetRequest request);

    /// Pedido em aberto mais recente do usuário — é o único que pode ser usado.
    Optional<PasswordResetRequest> findLatestOpenByUserId(UUID userId);

    /// Marca todos os pedidos em aberto como usados. Emitir código novo invalida
    /// os anteriores, senão um código antigo vazado continuaria valendo.
    void invalidateAllForUser(UUID userId, LocalDateTime at);
}
