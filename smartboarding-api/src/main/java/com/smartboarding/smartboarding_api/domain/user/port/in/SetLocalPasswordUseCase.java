package com.smartboarding.smartboarding_api.domain.user.port.in;

public interface SetLocalPasswordUseCase {
    /// Define a senha local de quem entrou pelo Google e ainda não tem uma.
    /// Quem já tem senha troca pelo fluxo de recuperação, que exige provar
    /// acesso ao e-mail.
    void setPassword(java.util.UUID userId, String rawPassword);
}
