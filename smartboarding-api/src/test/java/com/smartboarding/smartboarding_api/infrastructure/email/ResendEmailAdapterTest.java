package com.smartboarding.smartboarding_api.infrastructure.email;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class ResendEmailAdapterTest {

    @Test
    void send_sucesso_naoLancaExcecao() {
        RestClient.Builder builder = RestClient.builder().baseUrl("https://api.resend.com");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("https://api.resend.com/emails"))
                .andExpect(method(org.springframework.http.HttpMethod.POST))
                .andRespond(withSuccess("{\"id\":\"abc\"}", MediaType.APPLICATION_JSON));

        var adapter = new ResendEmailAdapter(builder.build(), "no-reply@smartboarding.com");

        adapter.send("aluno@example.com", "Convite", "<p>Olá</p>");

        server.verify();
    }

    @Test
    void send_falhaDoResend_propagaExcecao() {
        RestClient.Builder builder = RestClient.builder().baseUrl("https://api.resend.com");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("https://api.resend.com/emails"))
                .andRespond(withServerError());

        var adapter = new ResendEmailAdapter(builder.build(), "no-reply@smartboarding.com");

        assertThatThrownBy(() -> adapter.send("aluno@example.com", "Convite", "<p>Olá</p>"))
                .isInstanceOf(HttpServerErrorException.class);
    }
}
