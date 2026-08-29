package com.smartboarding.smartboarding_api.infrastructure.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {

    /**
     * O Spring Boot 4 (starter-webmvc) não registra um ObjectMapper por padrão
     * no contexto. Alguns use cases (ex.: ReportUseCaseImpl) dependem dele para
     * serializar o snapshot do relatório em JSON.
     *
     * findAndRegisterModules() registra os módulos disponíveis no classpath
     * (JavaTimeModule para LocalDate/LocalDateTime, etc.) automaticamente.
     */
    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper().findAndRegisterModules();
    }
}
