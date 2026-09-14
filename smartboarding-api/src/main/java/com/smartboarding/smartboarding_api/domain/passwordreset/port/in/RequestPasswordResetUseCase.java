package com.smartboarding.smartboarding_api.domain.passwordreset.port.in;

public interface RequestPasswordResetUseCase {

    /// Nunca sinaliza se a conta existe: o endpoint é público e uma resposta
    /// diferente por e-mail inexistente viraria detector de cadastro (RN22).
    void request(String email);
}
