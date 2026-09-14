package com.smartboarding.smartboarding_api.domain.profile.port.in;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ManageProfileUpdateUseCase {
    /// O aluno pede; nada muda no perfil até o admin aprovar.
    ProfileUpdateRequest request(UUID userId, ProfileUpdateRequest pedido);

    /// Pendente do próprio aluno, pra tela mostrar "em análise".
    Optional<ProfileUpdateRequest> myPending(UUID userId);

    /// Último pedido do aluno, em qualquer estado. O `myPending` só devolve
    /// PENDING, então a recusa -- e o motivo que o admin é obrigado a escrever
    /// -- nunca chegava a quem precisa dela pra corrigir e reenviar.
    Optional<ProfileUpdateRequest> myLatest(UUID userId);

    List<ProfileUpdateRequest> listPending();

    ProfileUpdateRequest approve(UUID requestId, UUID adminId);

    ProfileUpdateRequest reject(UUID requestId, String reason, UUID adminId);
}
