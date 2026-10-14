package com.smartboarding.smartboarding_api.infrastructure.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartboarding.smartboarding_api.domain.user.port.out.GoogleTokenVerifierPort;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Slf4j
@Component
public class GoogleTokenVerifierAdapter implements GoogleTokenVerifierPort {

    private static final String TOKENINFO = "https://oauth2.googleapis.com/tokeninfo";

    private static final ObjectMapper JSON = new ObjectMapper();

    private final RestClient http;
    private final String clientId;

    @Autowired
    public GoogleTokenVerifierAdapter(@Value("${google.client-id:}") String clientId) {
        this(RestClient.builder(), clientId);
    }

    GoogleTokenVerifierAdapter(RestClient.Builder builder, String clientId) {
        this.http = builder.build();
        this.clientId = clientId;
    }

    @Override
    public GoogleAccount verify(String idToken) {
        if (clientId == null || clientId.isBlank()) {
            throw new UnauthorizedException(
                    "Login com Google não está configurado neste servidor.");
        }

        JsonNode payload;
        try {
            String corpo = http.get()
                    .uri(TOKENINFO + "?id_token={t}", idToken)
                    .retrieve()
                    .body(String.class);
            payload = corpo == null ? null : JSON.readTree(corpo);
        } catch (Exception e) {
            log.warn("Falha ao validar token do Google: {}", e.getMessage());
            throw new UnauthorizedException("Não foi possível validar seu login do Google.");
        }
        if (payload == null) {
            throw new UnauthorizedException("Não foi possível validar seu login do Google.");
        }

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

        boolean verificado =
                "true".equalsIgnoreCase(payload.path("email_verified").asText("false"));

        return new GoogleAccount(sub, email, payload.path("name").asText(email), verificado);
    }
}
