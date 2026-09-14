package com.smartboarding.smartboarding_api.infrastructure.auth;

import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withBadRequest;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class GoogleTokenVerifierAdapterTest {

    private static final String CLIENT_ID = "123456789.apps.googleusercontent.com";

    private MockRestServiceServer google;

    /// Passa pelo RestClient de verdade, com os conversores de verdade: um teste
    /// que mockasse a resposta ja parseada nao teria pego o conversor errado
    /// escolhendo entre Jackson 2 e 3, que era o bug.
    private GoogleTokenVerifierAdapter comResposta(String clientId,
                                                   Runnable configuraResposta) {
        RestClient.Builder builder = RestClient.builder();
        google = MockRestServiceServer.bindTo(builder).build();
        configuraResposta.run();
        return new GoogleTokenVerifierAdapter(builder, clientId);
    }

    private void responde(String corpo) {
        google.expect(requestTo(containsString("id_token=token-do-google")))
                .andRespond(withSuccess(corpo, MediaType.APPLICATION_JSON));
    }

    /// O tokeninfo devolve email_verified como STRING. Lendo como booleano, todo
    /// login viraria "e-mail nao verificado".
    @Test
    void tokenValidoViraContaDoGoogle() {
        var adapter = comResposta(CLIENT_ID, () -> responde("""
                {"aud":"%s","sub":"104729","email":"fernanda@gmail.com",
                 "name":"Fernanda Lima","email_verified":"true"}""".formatted(CLIENT_ID)));

        var conta = adapter.verify("token-do-google");

        assertThat(conta.googleId()).isEqualTo("104729");
        assertThat(conta.email()).isEqualTo("fernanda@gmail.com");
        assertThat(conta.fullName()).isEqualTo("Fernanda Lima");
        assertThat(conta.emailVerified()).isTrue();
        google.verify();
    }

    @Test
    void semNomeCaiNoEmail() {
        var adapter = comResposta(CLIENT_ID, () -> responde("""
                {"aud":"%s","sub":"104729","email":"fernanda@gmail.com",
                 "email_verified":"true"}""".formatted(CLIENT_ID)));

        assertThat(adapter.verify("token-do-google").fullName()).isEqualTo("fernanda@gmail.com");
    }

    @Test
    void emailNaoVerificadoChegaComoFalso() {
        var adapter = comResposta(CLIENT_ID, () -> responde("""
                {"aud":"%s","sub":"104729","email":"fernanda@gmail.com",
                 "email_verified":"false"}""".formatted(CLIENT_ID)));

        assertThat(adapter.verify("token-do-google").emailVerified()).isFalse();
    }

    /// O "aud" e pra quem o token foi emitido. Sem conferir, um token valido de
    /// OUTRO aplicativo entraria nesta conta.
    @Test
    void tokenDeOutroAplicativoERecusado() {
        var adapter = comResposta(CLIENT_ID, () -> responde("""
                {"aud":"999.apps.googleusercontent.com","sub":"104729",
                 "email":"fernanda@gmail.com","email_verified":"true"}"""));

        assertThatThrownBy(() -> adapter.verify("token-do-google"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("inválido");
    }

    @Test
    void respostaSemSubOuEmailERecusada() {
        var adapter = comResposta(CLIENT_ID, () -> responde("""
                {"aud":"%s","email_verified":"true"}""".formatted(CLIENT_ID)));

        assertThatThrownBy(() -> adapter.verify("token-do-google"))
                .isInstanceOf(UnauthorizedException.class);
    }

    /// Sem client ID nao da pra saber se o token foi emitido PRA ESTE app.
    /// Aceitar assim faria valer token de qualquer outro aplicativo -- por isso
    /// a recusa vem antes de qualquer chamada de rede.
    @Test
    void semClientIdConfiguradoRecusaSemChamarARede() {
        var adapter = comResposta("", () -> {});

        assertThatThrownBy(() -> adapter.verify("qualquer-token"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("não está configurado");
        google.verify();
    }

    @Test
    void clientIdNuloTambemRecusa() {
        var adapter = comResposta(null, () -> {});

        assertThatThrownBy(() -> adapter.verify("qualquer-token"))
                .isInstanceOf(UnauthorizedException.class);
    }

    /// Com client ID configurado mas token invalido, o Google responde erro e o
    /// adapter traduz pra mensagem do usuario em vez de vazar a falha de rede.
    @Test
    void tokenInvalidoViraMensagemDeUsuario() {
        var adapter = comResposta(CLIENT_ID, () ->
                google.expect(requestTo(containsString("id_token=token-do-google")))
                        .andRespond(withBadRequest().body("""
                                {"error":"invalid_token"}""")
                                .contentType(MediaType.APPLICATION_JSON)));

        assertThatThrownBy(() -> adapter.verify("token-do-google"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("Google");
    }

    /// Corpo que nao e JSON nao pode subir como erro 500 do servidor.
    @Test
    void respostaQueNaoEJsonViraRecusa() {
        var adapter = comResposta(CLIENT_ID, () ->
                google.expect(requestTo(containsString("id_token=token-do-google")))
                        .andRespond(withSuccess("<html>erro</html>", MediaType.TEXT_HTML)));

        assertThatThrownBy(() -> adapter.verify("token-do-google"))
                .isInstanceOf(UnauthorizedException.class);
    }
}
