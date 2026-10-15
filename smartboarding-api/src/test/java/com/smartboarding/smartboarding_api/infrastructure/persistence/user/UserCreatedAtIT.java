package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/// Precisa de banco de verdade: o @CreationTimestamp é comportamento do
/// Hibernate no INSERT, e um teste com mock passaria mesmo sem ele.
@Testcontainers
@SpringBootTest
class UserCreatedAtIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    @Autowired
    UserRepositoryPort userRepository;

    @Test
    void usuarioNovoNasceComDataDeCriacao() {
        User salvo = userRepository.save(User.builder()
                .fullName("Aluno de Teste")
                .email("criado-" + UUID.randomUUID() + "@teste.com")
                .role(Role.STUDENT)
                .build());

        assertThat(salvo.getCreatedAt()).isNotNull();
    }

    @Test
    void contaSemSenha_comoAQueVemDoGoogle_tambemGanhaData() {
        User salvo = userRepository.save(User.builder()
                .fullName("Conta Google")
                .email("google-" + UUID.randomUUID() + "@gmail.com")
                .role(Role.STUDENT)
                .password(null)
                .build());

        assertThat(salvo.getPassword()).isNull();
        assertThat(salvo.getCreatedAt()).isNotNull();
    }
}
