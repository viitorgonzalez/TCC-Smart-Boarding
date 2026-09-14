package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

public interface SignupUseCase {
    /// Cria a conta do aluno, já ativa e SEM rota nenhuma. A rota chega depois,
    /// quando ele usa o código de convite (modelo Classroom).
    User signup(User user, String rawPassword);
}
