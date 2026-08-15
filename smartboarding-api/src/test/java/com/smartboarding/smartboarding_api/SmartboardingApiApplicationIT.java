package com.smartboarding.smartboarding_api;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Sobe o contexto Spring inteiro contra um Postgres real e efêmero — também valida
 * que as migrations Flyway aplicam num banco vazio. Precisa de Docker disponível
 * (local ou runner de CI); roda via `mvn verify`, não via `mvn test`.
 */
@Testcontainers
@SpringBootTest
class SmartboardingApiApplicationIT {

	@Container
	@ServiceConnection
	static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

	@Test
	void contextLoads() {
	}

}
