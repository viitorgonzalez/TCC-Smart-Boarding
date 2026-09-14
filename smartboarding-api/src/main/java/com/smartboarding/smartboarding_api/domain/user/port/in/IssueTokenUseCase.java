package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.application.user.AuthToken;
import com.smartboarding.smartboarding_api.domain.user.entity.User;

/// Emite a sessão para um usuário já autenticado por qualquer caminho.
///
/// Existe separado do login por senha porque o Google já provou a identidade —
/// exigir senha ali seria impossível (conta social pode não ter uma).
public interface IssueTokenUseCase {
    AuthToken issueFor(User user);
}
