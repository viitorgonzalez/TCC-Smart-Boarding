package com.smartboarding.smartboarding_api.infrastructure.auth;

import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoogleTokenVerifierAdapterTest {

    /// Sem client ID nao da pra saber se o token foi emitido PRA ESTE app.
    /// Aceitar assim faria valer token de qualquer outro aplicativo -- por isso
    /// a recusa vem antes de qualquer chamada de rede.
    @Test
    void semClientIdConfiguradoRecusaSemChamarORede() {
        var adapter = new GoogleTokenVerifierAdapter("");

        assertThatThrownBy(() -> adapter.verify("qualquer-token"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("não está configurado");
    }

    @Test
    void clientIdNuloTambemRecusa() {
        var adapter = new GoogleTokenVerifierAdapter(null);

        assertThatThrownBy(() -> adapter.verify("qualquer-token"))
                .isInstanceOf(UnauthorizedException.class);
    }

    /// Com client ID configurado mas token invalido, o Google responde erro e o
    /// adapter traduz pra mensagem do usuario em vez de vazar a falha de rede.
    @Test
    void tokenInvalidoViraMensagemDeUsuario() {
        var adapter = new GoogleTokenVerifierAdapter("123456789.apps.googleusercontent.com");

        assertThatThrownBy(() -> adapter.verify("token-que-o-google-recusa"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("Google");
    }
}
