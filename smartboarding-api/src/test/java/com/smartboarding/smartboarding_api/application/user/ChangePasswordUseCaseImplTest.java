package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ChangePasswordUseCaseImplTest {

    private static final UUID USUARIO = UUID.randomUUID();
    private static final String HASH_ATUAL = "$2b$10$hash-da-senha-atual";

    @Mock UserRepositoryPort userRepository;
    @Mock PasswordEncoder passwordEncoder;

    private ChangePasswordUseCaseImpl useCase;
    private User conta;

    @BeforeEach
    void setUp() {
        useCase = new ChangePasswordUseCaseImpl(userRepository, passwordEncoder);
        conta = User.builder().id(USUARIO).email("fernanda@edu.unifor.br")
                .password(HASH_ATUAL).build();
        when(userRepository.findById(USUARIO)).thenReturn(Optional.of(conta));
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(passwordEncoder.matches("atual123", HASH_ATUAL)).thenReturn(true);
        when(passwordEncoder.encode("nova456")).thenReturn("$2b$10$hash-da-nova");
    }

    @Test
    void trocaASenhaQuandoAAtualConfere() {
        useCase.changePassword(USUARIO, "atual123", "nova456");

        assertThat(conta.getPassword()).isEqualTo("$2b$10$hash-da-nova");
        verify(userRepository).save(conta);
    }

    @Test
    void recusaQuandoASenhaAtualEstaErrada() {
        assertThatThrownBy(() -> useCase.changePassword(USUARIO, "chutei", "nova456"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Senha atual incorreta");

        assertThat(conta.getPassword()).isEqualTo(HASH_ATUAL);
        verify(userRepository, never()).save(any());
    }

    @Test
    void recusaQuandoANovaEIgualAAtual() {
        when(passwordEncoder.matches("atual123", HASH_ATUAL)).thenReturn(true);

        assertThatThrownBy(() -> useCase.changePassword(USUARIO, "atual123", "atual123"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("diferente da atual");

        verify(userRepository, never()).save(any());
    }

    /// Conta de Google sem senha cai no POST (criar), não aqui: não há senha
    /// antiga pra provar posse.
    @Test
    void recusaQuemAindaNaoTemSenha() {
        conta.setPassword(null);

        assertThatThrownBy(() -> useCase.changePassword(USUARIO, "qualquer", "nova456"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("ainda não tem senha");

        verify(userRepository, never()).save(any());
    }

    @Test
    void recusaUsuarioInexistente() {
        when(userRepository.findById(USUARIO)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.changePassword(USUARIO, "atual123", "nova456"))
                .isInstanceOf(NotFoundException.class);
    }
}
