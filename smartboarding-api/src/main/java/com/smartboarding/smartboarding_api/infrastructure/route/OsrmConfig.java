package com.smartboarding.smartboarding_api.infrastructure.route;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class OsrmConfig {

    @Bean
    public RestClient osrmRestClient(
            @Value("${osrm.base-url:https://router.project-osrm.org}") String baseUrl) {
        return RestClient.builder().baseUrl(baseUrl).build();
    }
}
