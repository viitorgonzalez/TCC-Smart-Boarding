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

    @Test
    void respostaQueNaoEJsonViraRecusa() {
        var adapter = comResposta(CLIENT_ID, () ->
                google.expect(requestTo(containsString("id_token=token-do-google")))
                        .andRespond(withSuccess("<html>erro</html>", MediaType.TEXT_HTML)));

        assertThatThrownBy(() -> adapter.verify("token-do-google"))
                .isInstanceOf(UnauthorizedException.class);
    }
}
