package com.smartboarding.smartboarding_api.infrastructure.persistence.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;

/// O `reset()` roda SEM transação de propósito, então este update tem que abrir a
/// sua. Com @Modifying e nenhuma transação por perto o Hibernate recusa, e a
/// senha do aluno já teria sido trocada duas linhas antes -- ele fica com 500 e
/// um código que não serve mais.
@Testcontainers
@SpringBootTest
class PasswordResetRepositoryAdapterIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    PasswordResetRepositoryPort repository;

    @Test
    void invalidarPedidosAbreAPropriaTransacao() {
        assertThatCode(() -> repository.invalidateAllForUser(UUID.randomUUID(), LocalDateTime.now()))
                .doesNotThrowAnyException();
    }
}
