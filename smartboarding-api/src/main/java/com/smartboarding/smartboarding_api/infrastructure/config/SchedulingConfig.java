package com.smartboarding.smartboarding_api.infrastructure.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.time.Clock;
import java.time.ZoneId;

@Configuration
@EnableScheduling
public class SchedulingConfig {

    // Fuso explícito em vez do fuso da máquina: container sobe em UTC por padrão,
    // o que deslocaria em 3h o fechamento da lista (RN2/RN18) sem nenhum sinal.
    // As regras de horário também só são testáveis de forma determinística com o
    // "agora" injetável.
    @Bean
    public Clock clock(@Value("${app.timezone:America/Sao_Paulo}") String timezone) {
        return Clock.system(ZoneId.of(timezone));
    }
}
