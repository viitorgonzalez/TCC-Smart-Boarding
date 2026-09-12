package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SetLocalPasswordUseCaseImplTest {

    private static final UUID USUARIO = UUID.randomUUID();

    @Mock UserRepositoryPort userRepository;
    @Mock PasswordEncoder passwordEncoder;

    private SetLocalPasswordUseCaseImpl useCase;
    private User contaGoogle;

    @BeforeEach
    void setUp() {
        useCase = new SetLocalPasswordUseCaseImpl(userRepository, passwordEncoder);
        contaGoogle = User.builder().id(USUARIO).email("fernanda@edu.unifor.br")
                .googleId("108234567890123456789").build();
        when(userRepository.findById(USUARIO)).thenReturn(Optional.of(contaGoogle));
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$hashNovo");
    }

    /// O ponto do fluxo: quem entrou pelo Google passa a poder entrar tambem
    /// por e-mail e senha.
    @Test
    void contaDoGoogleGanhaSenhaLocalEFicaComOsDoisCaminhos() {
        useCase.setPassword(USUARIO, "minhaSenha1");

        assertThat(contaGoogle.hasPassword()).isTrue();
        assertThat(contaGoogle.hasGoogle()).isTrue();
        verify(passwordEncoder).encode("minhaSenha1");
    }

    @Test
    void aSenhaCruaNuncaEGravada() {
        useCase.setPassword(USUARIO, "minhaSenha1");

        assertThat(contaGoogle.getPassword()).doesNotContain("minhaSenha1");
    }

    /// Definir, nao trocar. Permitir sobrescrever aqui daria troca de senha sem
    /// provar posse da antiga: quem pegasse o celular desbloqueado tomaria a
    /// conta. Trocar e pelo fluxo de recuperacao, que exige o e-mail.
    @Test
    void quemJaTemSenhaNaoSobrescrevePorAqui() {
        contaGoogle.setPassword("$2a$10$hashAntigo");

        assertThatThrownBy(() -> useCase.setPassword(USUARIO, "outraSenha1"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Esqueci minha senha");

        assertThat(contaGoogle.getPassword()).isEqualTo("$2a$10$hashAntigo");
        verify(userRepository, never()).save(any());
    }

    @Test
    void usuarioInexistenteEstoura() {
        UUID outro = UUID.randomUUID();
        when(userRepository.findById(outro)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.setPassword(outro, "minhaSenha1"))
                .isInstanceOf(NotFoundException.class);
    }
}
