package com.smartboarding.smartboarding_api.infrastructure.email;

import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class ResendEmailAdapter implements EmailPort {

    private final RestClient restClient;
    private final String fromEmail;

    public ResendEmailAdapter(
            @Qualifier("resendRestClient") RestClient restClient,
            @Value("${resend.from.email:}") String fromEmail) {
        this.restClient = restClient;
        this.fromEmail = fromEmail;
    }

    @Override
    public void send(String to, String subject, String htmlBody) {
        restClient.post()
                .uri("/emails")
                .body(Map.of(
                        "from", fromEmail,
                        "to", List.of(to),
                        "subject", subject,
                        "html", htmlBody))
                .retrieve()
                .toBodilessEntity();
        log.info("E-mail enviado via Resend pra {}: '{}'", to, subject);
    }
}
