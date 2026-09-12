package com.smartboarding.smartboarding_api.domain.passwordreset.port.in;

public interface ResetPasswordUseCase {

    /// Troca a senha e queima o código. E-mail desconhecido devolve o mesmo erro
    /// de código inválido — distinguir os dois casos revelaria quais contas existem.
    void reset(String email, String code, String newPassword);
}
