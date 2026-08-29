package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthUseCaseImplTest {

    @Mock UserRepositoryPort userRepository;
    @Mock PasswordEncoder passwordEncoder;

    private AuthUseCaseImpl useCase() {
        return new AuthUseCaseImpl(userRepository, passwordEncoder, null);
    }

    @Test
    void registrarAdminFuncionaNormalmente() {
        var useCase = useCase();
        var admin = User.builder().email("novo@admin.com").fullName("Novo Admin").role(Role.ADMIN).build();
        when(userRepository.existsByEmail("novo@admin.com")).thenReturn(false);
        when(passwordEncoder.encode("senha123")).thenReturn("hash");
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var saved = useCase.execute(admin, "senha123");

        assertThat(saved.getRole()).isEqualTo(Role.ADMIN);
        assertThat(saved.getPassword()).isEqualTo("hash");
    }

    @Test
    void registrarAlunoDiretoLancaExcecao() {
        var useCase = useCase();
        var student = User.builder().email("aluno@edu.com").fullName("Aluno").role(Role.STUDENT).build();

        assertThatThrownBy(() -> useCase.execute(student, "senha123"))
                .isInstanceOf(BadRequestException.class);
        verify(userRepository, never()).save(any());
        verify(passwordEncoder, never()).encode(anyString());
    }

    @Test
    void registrarSemPapelLancaExcecao() {
        var useCase = useCase();
        var semPapel = User.builder().email("x@y.com").fullName("Sem Papel").build();

        assertThatThrownBy(() -> useCase.execute(semPapel, "senha123"))
                .isInstanceOf(BadRequestException.class);
        verify(userRepository, never()).save(any());
    }
}
