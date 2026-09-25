package com.smartboarding.smartboarding_api.infrastructure.route;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class OsrmConfig {

    /// O servidor público é o de demonstração do projeto OSRM: sem SLA e com
    /// limite de uso. Externalizado pra que o deploy aponte pra instância
    /// própria trocando uma variável, não código.
    @Bean
    public RestClient osrmRestClient(
            @Value("${osrm.base-url:https://router.project-osrm.org}") String baseUrl) {
        return RestClient.builder().baseUrl(baseUrl).build();
    }
}
