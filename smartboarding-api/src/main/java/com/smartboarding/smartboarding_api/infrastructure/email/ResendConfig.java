package com.smartboarding.smartboarding_api.infrastructure.email;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class ResendConfig {

    @Bean
    public RestClient resendRestClient(@Value("${resend.api.key:}") String apiKey) {
        return RestClient.builder()
                .baseUrl("https://api.resend.com")
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .build();
    }
}
