package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserUseCaseImplTest {

    @Mock UserRepositoryPort repository;

    private User aluno(String nome) {
        return User.builder().id(UUID.randomUUID()).fullName(nome)
                .email(nome.toLowerCase() + "@edu.unifor.br").build();
    }

    @Test
    void findByRouteFiltraPelaRota() {
        UUID rota = UUID.randomUUID();
        var alunos = List.of(aluno("Fernanda"));
        when(repository.findByRouteId(rota)).thenReturn(alunos);

        assertThat(new UserUseCaseImpl(repository).findByRoute(rota)).isEqualTo(alunos);
    }

    @Test
    void findAllDevolveTodos() {
        var todos = List.of(aluno("Fernanda"), aluno("Bruno"));
        when(repository.findAll()).thenReturn(todos);

        assertThat(new UserUseCaseImpl(repository).findAll()).hasSize(2);
    }

    @Test
    void findByIdExistenteDevolveOUsuario() {
        var user = aluno("Fernanda");
        when(repository.findById(user.getId())).thenReturn(Optional.of(user));

        assertThat(new UserUseCaseImpl(repository).findById(user.getId())).isSameAs(user);
    }

    @Test
    void findByIdInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> new UserUseCaseImpl(repository).findById(id))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining(id.toString());
    }
}
