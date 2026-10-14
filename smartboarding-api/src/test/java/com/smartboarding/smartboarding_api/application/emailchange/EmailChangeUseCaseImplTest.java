package com.smartboarding.smartboarding_api.application.emailchange;

import com.smartboarding.smartboarding_api.domain.emailchange.entity.EmailChangeRequest;
import com.smartboarding.smartboarding_api.domain.emailchange.port.out.EmailChangeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
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
class EmailChangeUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 8, 10, 0);
    private static final UUID USER_ID = UUID.randomUUID();
    private static final String EMAIL_ATUAL = "aluno@edu.unifor.br";
    private static final String EMAIL_NOVO = "aluno.novo@edu.unifor.br";

    @Mock EmailChangeRepositoryPort changeRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock EmailPort emailPort;
    @Mock PasswordEncoder passwordEncoder;

    private EmailChangeUseCaseImpl useCase;

    private Clock clockAt(LocalDateTime moment) {
        return Clock.fixed(moment.atZone(ZONE).toInstant(), ZONE);
    }

    @BeforeEach
    void setUp() {
        User user = User.builder().id(USER_ID).email(EMAIL_ATUAL).build();
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(user));
        when(userRepository.existsByEmail(EMAIL_NOVO)).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hash-fake");
        when(changeRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.empty());
        useCase = new EmailChangeUseCaseImpl(changeRepository, userRepository, emailPort,
                passwordEncoder, clockAt(NOW), 15, 5, 60);
    }

    @Test
    void pedidoGravaSoOHashComValidadeCurta() {
        useCase.request(USER_ID, EMAIL_NOVO);

        ArgumentCaptor<EmailChangeRequest> captor = ArgumentCaptor.forClass(EmailChangeRequest.class);
        verify(changeRepository).save(captor.capture());
        EmailChangeRequest saved = captor.getValue();

        assertThat(saved.getUserId()).isEqualTo(USER_ID);
        assertThat(saved.getNewEmail()).isEqualTo(EMAIL_NOVO);
        assertThat(saved.getCodeHash()).isEqualTo("hash-fake");
        assertThat(saved.getExpiresAt()).isEqualTo(NOW.plusMinutes(15));
        assertThat(saved.getAttempts()).isZero();
    }

    @Test
    void normalizaParaMinusculoAntesDeGravar() {
        useCase.request(USER_ID, "  ALUNO.NOVO@edu.unifor.br  ");

        ArgumentCaptor<EmailChangeRequest> captor = ArgumentCaptor.forClass(EmailChangeRequest.class);
        verify(changeRepository).save(captor.capture());
        assertThat(captor.getValue().getNewEmail()).isEqualTo("aluno.novo@edu.unifor.br");
    }

    @Test
    void codigoVaiProEmailNovoNaoProAtual() {
        useCase.request(USER_ID, EMAIL_NOVO);

        verify(emailPort).send(eq(EMAIL_NOVO), anyString(), anyString());
        verify(emailPort, never()).send(eq(EMAIL_ATUAL), any(), any());
    }

    @Test
    void emailLevaCodigoDeSeisDigitos() {
        useCase.request(USER_ID, EMAIL_NOVO);

        ArgumentCaptor<String> body = ArgumentCaptor.forClass(String.class);
        verify(emailPort).send(eq(EMAIL_NOVO), anyString(), body.capture());
        assertThat(body.getValue()).containsPattern("\\d{6}");
    }

    @Test
    void pedirOMesmoEmailAtualEhRecusado() {
        assertThatThrownBy(() -> useCase.request(USER_ID, EMAIL_ATUAL))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "SAME_EMAIL");

        verify(changeRepository, never()).save(any());
    }

    @Test
    void emailJaUsadoPorOutraContaEhRecusado() {
        when(userRepository.existsByEmail(EMAIL_NOVO)).thenReturn(true);

        assertThatThrownBy(() -> useCase.request(USER_ID, EMAIL_NOVO))
                .isInstanceOf(ConflictException.class)
                .hasFieldOrPropertyWithValue("code", "EMAIL_ALREADY_EXISTS");

        verify(changeRepository, never()).save(any());
    }

    @Test
    void pedidoDentroDoCooldownEhRecusado() {
        EmailChangeRequest recente = EmailChangeRequest.builder()
                .userId(USER_ID).newEmail(EMAIL_NOVO).codeHash("hash").expiresAt(NOW.plusMinutes(15))
                .createdAt(NOW.minusSeconds(30)).build();
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(recente));

        assertThatThrownBy(() -> useCase.request(USER_ID, EMAIL_NOVO))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "TOO_SOON");

        verify(changeRepository, never()).save(any());
    }

    @Test
    void pedirCodigoNovoInvalidaOsAnteriores() {
        useCase.request(USER_ID, EMAIL_NOVO);

        verify(changeRepository).invalidateAllForUser(USER_ID, NOW);
    }

    @Test
    void falhaDeEmailNaoDesfazOPedido() {
        doThrow(new RuntimeException("Resend fora")).when(emailPort).send(any(), any(), any());

        useCase.request(USER_ID, EMAIL_NOVO);

        verify(changeRepository).save(any());
    }

    private EmailChangeRequest pedidoAberto(String hash, int tentativas, LocalDateTime expiraEm) {
        return EmailChangeRequest.builder()
                .id(UUID.randomUUID())
                .userId(USER_ID)
                .newEmail(EMAIL_NOVO)
                .codeHash(hash)
                .expiresAt(expiraEm)
                .attempts(tentativas)
                .createdAt(NOW.minusMinutes(1))
                .build();
    }

    @Test
    void codigoCorretoTrocaOEmailEQueimaOPedido() {
        EmailChangeRequest pedido = pedidoAberto("hash-do-codigo", 0, NOW.plusMinutes(10));
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("123456", "hash-do-codigo")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        useCase.confirm(USER_ID, "123456");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(userCaptor.getValue().getEmail()).isEqualTo(EMAIL_NOVO);
        assertThat(pedido.getUsedAt()).isEqualTo(NOW);
    }

    @Test
    void avisaOEmailAntigoDepoisDeTrocar() {
        EmailChangeRequest pedido = pedidoAberto("hash-do-codigo", 0, NOW.plusMinutes(10));
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("123456", "hash-do-codigo")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        useCase.confirm(USER_ID, "123456");

        verify(emailPort).send(eq(EMAIL_ATUAL), anyString(), contains(EMAIL_NOVO));
    }

    @Test
    void emailJaUsadoNaConfirmacaoEhRecusado() {
        EmailChangeRequest pedido = pedidoAberto("hash-do-codigo", 0, NOW.plusMinutes(10));
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("123456", "hash-do-codigo")).thenReturn(true);
        when(userRepository.existsByEmail(EMAIL_NOVO)).thenReturn(true);

        assertThatThrownBy(() -> useCase.confirm(USER_ID, "123456"))
                .isInstanceOf(ConflictException.class)
                .hasFieldOrPropertyWithValue("code", "EMAIL_ALREADY_EXISTS");

        verify(userRepository, never()).save(any());
    }

    @Test
    void codigoErradoIncrementaTentativasELanca() {
        EmailChangeRequest pedido = pedidoAberto("hash-do-codigo", 2, NOW.plusMinutes(10));
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("000000", "hash-do-codigo")).thenReturn(false);

        assertThatThrownBy(() -> useCase.confirm(USER_ID, "000000"))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "INVALID_CODE");

        assertThat(pedido.getAttempts()).isEqualTo(3);
        verify(changeRepository).save(pedido);
        verify(userRepository, never()).save(any());
    }

    @Test
    void limiteDeTentativasEhAtingido() {
        EmailChangeRequest pedido = pedidoAberto("hash-do-codigo", 5, NOW.plusMinutes(10));
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));

        assertThatThrownBy(() -> useCase.confirm(USER_ID, "000000"))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "TOO_MANY_ATTEMPTS");

        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    void codigoExpiradoEhRecusado() {
        when(changeRepository.findLatestOpenByUserId(USER_ID))
                .thenReturn(Optional.of(pedidoAberto("hash-do-codigo", 0, NOW.minusMinutes(1))));

        assertThatThrownBy(() -> useCase.confirm(USER_ID, "123456"))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "CODE_EXPIRED");
    }

    @Test
    void semPedidoAbertoDevolveCodigoInvalido() {
        when(changeRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.confirm(USER_ID, "123456"))
                .isInstanceOf(BadRequestException.class)
                .hasFieldOrPropertyWithValue("code", "INVALID_CODE");
    }
}
