package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken;
import com.smartboarding.smartboarding_api.domain.notification.port.out.DeviceTokenRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

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
class DeviceTokenUseCaseImplTest {

    private static final UUID USER = UUID.randomUUID();
    private static final String TOKEN = "fcm-token-abc";

    @Mock DeviceTokenRepositoryPort deviceTokenRepository;
    @Mock UserRepositoryPort userRepository;

    private DeviceTokenUseCaseImpl useCase;
    private User user;

    @BeforeEach
    void setUp() {
        useCase = new DeviceTokenUseCaseImpl(deviceTokenRepository, userRepository);
        user = User.builder().id(USER).fullName("Fernanda").email("fernanda@edu.unifor.br").build();
        when(userRepository.findById(USER)).thenReturn(Optional.of(user));
        when(deviceTokenRepository.findByUserIdAndToken(any(), any())).thenReturn(Optional.empty());
    }

    @Test
    void tokenNovoEGravadoComOUsuarioEAPlataforma() {
        useCase.execute(USER, TOKEN, "android");

        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(deviceTokenRepository).save(captor.capture());
        assertThat(captor.getValue().getToken()).isEqualTo(TOKEN);
        assertThat(captor.getValue().getPlatform()).isEqualTo("android");
        assertThat(captor.getValue().getUser()).isSameAs(user);
    }

    /// Reinstalar o app devolve o mesmo token: precisa revalidar o existente, não
    /// criar um segundo registro pro mesmo par usuário+token.
    @Test
    void tokenJaRegistradoNaoDuplica() {
        DeviceToken existing = DeviceToken.builder().user(user).token(TOKEN).platform("ios").build();
        when(deviceTokenRepository.findByUserIdAndToken(USER, TOKEN)).thenReturn(Optional.of(existing));

        useCase.execute(USER, TOKEN, "ios");

        verify(deviceTokenRepository).save(existing);
    }

    @Test
    void usuarioInexistenteNaoGravaToken() {
        UUID desconhecido = UUID.randomUUID();
        when(userRepository.findById(desconhecido)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.execute(desconhecido, TOKEN, "android"))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining(desconhecido.toString());

        verify(deviceTokenRepository, never()).save(any());
    }

    @Test
    void logoutRemoveTodosOsTokensDoUsuario() {
        useCase.execute(USER);

        verify(deviceTokenRepository).deleteByUserId(USER);
    }
}
