package com.smartboarding.smartboarding_api.domain.user.port.out;

/// Verificação do ID token do Google. Fica atrás de porta porque a checagem
/// depende de credencial (o client ID) e de rede — o use case precisa ser
/// testável sem nenhum dos dois.
public interface GoogleTokenVerifierPort {

    /// Dados que o Google afirma sobre a conta, já verificados.
    ///
    /// [emailVerified] é o que separa login social de sequestro de conta: sem
    /// ele, alguém cadastra um Google com o e-mail de outra pessoa e assume a
    /// conta dela por vínculo automático.
    record GoogleAccount(String googleId, String email, String fullName, boolean emailVerified) {}

    /// Devolve os dados quando o token é válido e emitido para este app.
    /// Lança quando não é.
    GoogleAccount verify(String idToken);
}
