package com.smartboarding.smartboarding_api.infrastructure.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.smartboarding.smartboarding_api.domain.user.port.out.GoogleTokenVerifierPort;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/// Valida o ID token contra o próprio Google.
///
/// Usa o endpoint tokeninfo em vez de verificar a assinatura localmente: sem
/// biblioteca extra, e o Google faz a checagem de assinatura, emissor e prazo.
/// A contrapartida é uma chamada de rede por login — aceitável no volume de um
/// transporte universitário, e o caminho mais difícil de implementar errado.
@Slf4j
@Component
public class GoogleTokenVerifierAdapter implements GoogleTokenVerifierPort {

    private static final String TOKENINFO = "https://oauth2.googleapis.com/tokeninfo";

    private final RestClient http = RestClient.create();
    private final String clientId;

    public GoogleTokenVerifierAdapter(@Value("${google.client-id:}") String clientId) {
        this.clientId = clientId;
    }

    @Override
    public GoogleAccount verify(String idToken) {
        if (clientId == null || clientId.isBlank()) {
            // Sem client ID não dá pra saber se o token foi emitido PRA ESTE app.
            // Aceitar assim deixaria valer token de qualquer outro aplicativo.
            throw new UnauthorizedException(
                    "Login com Google não está configurado neste servidor.");
        }

        JsonNode payload;
        try {
            payload = http.get()
                    .uri(TOKENINFO + "?id_token={t}", idToken)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (Exception e) {
            log.warn("Falha ao validar token do Google: {}", e.getMessage());
            throw new UnauthorizedException("Não foi possível validar seu login do Google.");
        }
        if (payload == null) {
            throw new UnauthorizedException("Não foi possível validar seu login do Google.");
        }

        // O "aud" é pra quem o token foi emitido. Sem conferir, um token válido
        // de OUTRO app seria aceito aqui e daria acesso a esta conta.
        String aud = payload.path("aud").asText("");
        if (!clientId.equals(aud)) {
            log.warn("Token do Google emitido para outro aplicativo");
            throw new UnauthorizedException("Login do Google inválido.");
        }

        String sub = payload.path("sub").asText("");
        String email = payload.path("email").asText("");
        if (sub.isBlank() || email.isBlank()) {
            throw new UnauthorizedException("Login do Google inválido.");
        }

        // O tokeninfo devolve "true"/"false" como STRING, não booleano.
        boolean verificado =
                "true".equalsIgnoreCase(payload.path("email_verified").asText("false"));

        return new GoogleAccount(sub, email, payload.path("name").asText(email), verificado);
    }
}
