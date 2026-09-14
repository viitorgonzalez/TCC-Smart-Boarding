package com.smartboarding.smartboarding_api;

import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

/// Sobe a aplicação com o mesmo `flyway.locations` de produção — só o schema,
/// sem `db/seed`.
///
/// Prova as duas metades do problema que separou os dois diretórios: que a
/// cadeia de migrations aplica sozinha num banco vazio (V3, V9, V22 e V26 mexem
/// em `users` e precisam ser no-op sem as linhas de demonstração), e que o
/// ambiente não nasce com administrador nenhum — que é a condição de que o
/// bootstrap por `BOOTSTRAP_ADMIN_EMAIL` depende pra existir.
@Testcontainers
@SpringBootTest
@TestPropertySource(properties = "spring.flyway.locations=classpath:db/migration")
class ProductionMigrationsIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    UserRepositoryPort userRepository;

    @Test
    void semOSeedOBancoNasceVazioESemAdmin() {
        assertThat(userRepository.findAll()).isEmpty();
        assertThat(userRepository.countAdmins()).isZero();
    }
}
