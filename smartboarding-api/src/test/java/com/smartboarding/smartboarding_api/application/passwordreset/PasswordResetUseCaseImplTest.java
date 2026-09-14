package com.smartboarding.smartboarding_api.application.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PasswordResetUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 8, 10, 0);
    private static final UUID USER_ID = UUID.randomUUID();
    private static final String EMAIL = "aluno@edu.unifor.br";

    @Mock PasswordResetRepositoryPort resetRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock EmailPort emailPort;
    @Mock PasswordEncoder passwordEncoder;

    private PasswordResetUseCaseImpl useCase;

    private Clock clockAt(LocalDateTime moment) {
        return Clock.fixed(moment.atZone(ZONE).toInstant(), ZONE);
    }

    @BeforeEach
    void setUp() {
        User user = User.builder().id(USER_ID).email(EMAIL).build();
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(user));
        when(userRepository.findByEmail("naoexiste@edu.unifor.br")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("hash-fake");
        when(resetRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.empty());
        useCase = new PasswordResetUseCaseImpl(resetRepository, userRepository, emailPort,
                passwordEncoder, clockAt(NOW), 15, 5, 60);
    }

    @Test
    void emailInexistenteNaoGeraPedidoNemEmail() {
        useCase.request("naoexiste@edu.unifor.br");

        verify(resetRepository, never()).save(any());
        verify(emailPort, never()).send(any(), any(), any());
    }

    @Test
    void pedidoGravaSoOHashComValidadeCurta() {
        useCase.request(EMAIL);

        ArgumentCaptor<PasswordResetRequest> captor = ArgumentCaptor.forClass(PasswordResetRequest.class);
        verify(resetRepository).save(captor.capture());
        PasswordResetRequest saved = captor.getValue();

        assertThat(saved.getUserId()).isEqualTo(USER_ID);
        assertThat(saved.getCodeHash()).isEqualTo("hash-fake");
        assertThat(saved.getExpiresAt()).isEqualTo(NOW.plusMinutes(15));
        assertThat(saved.getAttempts()).isZero();
        assertThat(saved.getUsedAt()).isNull();
    }

    @Test
    void emailLevaCodigoDeSeisDigitos() {
        useCase.request(EMAIL);

        ArgumentCaptor<String> body = ArgumentCaptor.forClass(String.class);
        verify(emailPort).send(eq(EMAIL), anyString(), body.capture());
        assertThat(body.getValue()).containsPattern("\\d{6}");
    }

    @Test
    void emitirCodigoNovoInvalidaOsAnteriores() {
        useCase.request(EMAIL);

        verify(resetRepository).invalidateAllForUser(USER_ID, NOW);
    }

    @Test
    void pedidoDentroDoCooldownNaoEnviaDeNovo() {
        PasswordResetRequest recente = PasswordResetRequest.builder()
                .userId(USER_ID).codeHash("hash").expiresAt(NOW.plusMinutes(15))
                .createdAt(NOW.minusSeconds(30)).build();
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(recente));

        useCase.request(EMAIL);

        verify(resetRepository, never()).save(any());
        verify(emailPort, never()).send(any(), any(), any());
    }

    @Test
    void falhaDeEmailNaoDesfazOPedido() {
        doThrow(new RuntimeException("Resend fora")).when(emailPort).send(any(), any(), any());

        useCase.request(EMAIL);

        verify(resetRepository).save(any());
    }

    private PasswordResetRequest pedidoAberto(String hash, int tentativas, LocalDateTime expiraEm) {
        return PasswordResetRequest.builder()
                .id(UUID.randomUUID())
                .userId(USER_ID)
                .codeHash(hash)
                .expiresAt(expiraEm)
                .attempts(tentativas)
                .createdAt(NOW.minusMinutes(1))
                .build();
    }

    @Test
    void codigoCorretoTrocaASenhaEQueimaOPedido() {
        PasswordResetRequest pedido = pedidoAberto("hash-do-codigo", 0, NOW.plusMinutes(10));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("123456", "hash-do-codigo")).thenReturn(true);
        when(passwordEncoder.encode("senhaNova1")).thenReturn("hash-da-senha-nova");
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        useCase.reset(EMAIL, "123456", "senhaNova1");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(userCaptor.getValue().getPassword()).isEqualTo("hash-da-senha-nova");
        assertThat(pedido.getUsedAt()).isEqualTo(NOW);
    }

    @Test
    void codigoErradoIncrementaTentativasELanca() {
        PasswordResetRequest pedido = pedidoAberto("hash-do-codigo", 2, NOW.plusMinutes(10));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("000000", "hash-do-codigo")).thenReturn(false);

        assertThatThrownBy(() -> useCase.reset(EMAIL, "000000", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");

        assertThat(pedido.getAttempts()).isEqualTo(3);
        verify(resetRepository).save(pedido);
        verify(userRepository, never()).save(any());
    }

    @Test
    void limiteDeTentativasEhAtingido() {
        // O contador só chega aqui porque o incremento não vive numa transação que
        // sofre rollback na exceção. Se alguém marcar reset() como @Transactional,
        // este teste continua passando com mock -- mas o comportamento real quebra.
        PasswordResetRequest pedido = pedidoAberto("hash-do-codigo", 5, NOW.plusMinutes(10));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));

        assertThatThrownBy(() -> useCase.reset(EMAIL, "000000", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Muitas tentativas");

        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    void codigoExpiradoEhRecusado() {
        when(resetRepository.findLatestOpenByUserId(USER_ID))
                .thenReturn(Optional.of(pedidoAberto("hash-do-codigo", 0, NOW.minusMinutes(1))));

        assertThatThrownBy(() -> useCase.reset(EMAIL, "123456", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("expirado");
    }

    @Test
    void emailDesconhecidoDevolveOMesmoErroDeCodigoInvalido() {
        assertThatThrownBy(() -> useCase.reset("naoexiste@edu.unifor.br", "123456", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");
    }

    @Test
    void semPedidoAbertoDevolveCodigoInvalido() {
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.reset(EMAIL, "123456", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");
    }
}
