package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.GoogleTokenVerifierPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
class GoogleSignInUseCaseImplTest {

    private static final String GOOGLE_ID = "108234567890123456789";
    private static final String EMAIL = "fernanda@edu.unifor.br";

    @Mock GoogleTokenVerifierPort verifier;
    @Mock UserRepositoryPort userRepository;

    private GoogleSignInUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = comBootstrap("");
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(userRepository.findByGoogleId(any())).thenReturn(Optional.empty());
        when(userRepository.findByEmail(any())).thenReturn(Optional.empty());
        contaGoogle(true);
    }

    private GoogleSignInUseCaseImpl comBootstrap(String bootstrapAdminEmail) {
        return new GoogleSignInUseCaseImpl(verifier, userRepository,
                new BootstrapAdminPolicy(userRepository, bootstrapAdminEmail));
    }

    private void contaGoogle(boolean verificado) {
        when(verifier.verify(any())).thenReturn(new GoogleTokenVerifierPort.GoogleAccount(
                GOOGLE_ID, EMAIL, "Fernanda Lima", verificado));
    }

    @Test
    void primeiroLoginCriaAContaSemSenhaLocal() {
        User criado = useCase.signIn("token");

        assertThat(criado.getEmail()).isEqualTo(EMAIL);
        assertThat(criado.getGoogleId()).isEqualTo(GOOGLE_ID);
        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
        assertThat(criado.isActive()).isTrue();
        assertThat(criado.hasPassword()).isFalse();
        assertThat(criado.hasGoogle()).isTrue();
    }

    @Test
    void loginSeguinteReusaAContaVinculada() {
        var existente = User.builder().id(UUID.randomUUID()).email(EMAIL)
                .googleId(GOOGLE_ID).fullName("Fernanda Lima").build();
        when(userRepository.findByGoogleId(GOOGLE_ID)).thenReturn(Optional.of(existente));

        assertThat(useCase.signIn("token")).isSameAs(existente);
        verify(userRepository, never()).save(any());
    }

    @Test
    void emailNaoVerificadoNoGoogleERecusado() {
        contaGoogle(false);
        var vitima = User.builder().id(UUID.randomUUID()).email(EMAIL)
                .password("$2a$10$hash").build();
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(vitima));

        assertThatThrownBy(() -> useCase.signIn("token"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("não está verificado");

        assertThat(vitima.getGoogleId()).isNull();
        verify(userRepository, never()).save(any());
    }

    @Test
    void mesmoEmailComContaPorSenhaVinculaEmVezDeDuplicar() {
        var existente = User.builder().id(UUID.randomUUID()).email(EMAIL)
                .password("$2a$10$hash").fullName("Fernanda Lima").build();
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(existente));

        User resultado = useCase.signIn("token");

        assertThat(resultado.getId()).isEqualTo(existente.getId());
        assertThat(resultado.getGoogleId()).isEqualTo(GOOGLE_ID);
        assertThat(resultado.hasPassword()).isTrue();
        assertThat(resultado.hasGoogle()).isTrue();
    }

    @Test
    void tokenInvalidoNaoCriaConta() {
        when(verifier.verify(any())).thenThrow(new UnauthorizedException("Login do Google inválido."));

        assertThatThrownBy(() -> useCase.signIn("lixo"))
                .isInstanceOf(UnauthorizedException.class);

        verify(userRepository, never()).save(any());
    }

    @Test
    void contaCriadaPeloGoogleEsempreStudent() {
        assertThat(useCase.signIn("token").getRole()).isEqualTo(Role.STUDENT);
    }

    @Test
    void primeiroLoginComOEmailDeBootstrapNasceAdmin() {
        when(userRepository.countAdmins()).thenReturn(0L);

        assertThat(comBootstrap(EMAIL).signIn("token").getRole()).isEqualTo(Role.ADMIN);
    }

    @Test
    void comAdminExistenteOLoginPeloGoogleNaoConcedeNada() {
        when(userRepository.countAdmins()).thenReturn(1L);

        assertThat(comBootstrap(EMAIL).signIn("token").getRole()).isEqualTo(Role.STUDENT);
    }

    @Test
    void outroEmailNoGoogleNaoVirapAdminNemComZeroAdmins() {
        when(userRepository.countAdmins()).thenReturn(0L);

        assertThat(comBootstrap("chefe@prefeitura.gov.br").signIn("token").getRole())
                .isEqualTo(Role.STUDENT);
    }

    @Test
    void grafiaComOutraCaixaNaoCasaNoCaminhoDoGoogle() {
        when(userRepository.countAdmins()).thenReturn(0L);

        assertThat(comBootstrap(EMAIL.toUpperCase()).signIn("token").getRole())
                .isEqualTo(Role.STUDENT);
    }

    @Test
    void vincularContaExistenteNaoConcedeAdminPeloBootstrap() {
        when(userRepository.countAdmins()).thenReturn(0L);
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(
                User.builder().id(UUID.randomUUID()).email(EMAIL).role(Role.STUDENT)
                        .password("$2a$10$hash").fullName("Fernanda Lima").build()));

        assertThat(comBootstrap(EMAIL).signIn("token").getRole()).isEqualTo(Role.STUDENT);
    }

    @Test
    void contaDesativadaNaoEntraNemPeloGoogle() {
        org.mockito.Mockito.reset(userRepository);
        when(userRepository.findByGoogleId(GOOGLE_ID)).thenReturn(Optional.of(
                User.builder().id(java.util.UUID.randomUUID()).email(EMAIL)
                        .googleId(GOOGLE_ID).isActive(false).build()));

        assertThatThrownBy(() -> useCase.signIn("token"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("desativada");
    }

    @Test
    void vincularAoGoogleNaoReviveContaDesativada() {
        org.mockito.Mockito.reset(userRepository);
        when(userRepository.findByGoogleId(any())).thenReturn(Optional.empty());
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(
                User.builder().id(java.util.UUID.randomUUID()).email(EMAIL)
                        .password("$2a$10$hash").isActive(false).build()));

        assertThatThrownBy(() -> useCase.signIn("token"))
                .isInstanceOf(UnauthorizedException.class);

        org.mockito.Mockito.verify(userRepository, org.mockito.Mockito.never()).save(any());
    }
}
