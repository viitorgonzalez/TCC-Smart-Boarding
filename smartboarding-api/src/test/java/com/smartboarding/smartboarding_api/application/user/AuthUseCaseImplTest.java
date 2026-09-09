package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;

import java.time.Instant;
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
class AuthUseCaseImplTest {

    @Mock UserRepositoryPort userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtEncoder jwtEncoder;

    private AuthUseCaseImpl useCase() {
        return new AuthUseCaseImpl(userRepository, passwordEncoder, null);
    }

    /// Só os testes de login precisam do encoder; o de registro passa null de
    /// propósito, pra deixar claro que não emite token.
    private AuthUseCaseImpl useCaseComToken() {
        return new AuthUseCaseImpl(userRepository, passwordEncoder, jwtEncoder);
    }

    private User contaAtiva(String email, Role role) {
        return User.builder().id(UUID.randomUUID()).email(email).fullName("Fernanda Lima")
                .password("$2a$10$hash").role(role).isActive(true).build();
    }

    private void encoderDevolve(String tokenValue) {
        when(jwtEncoder.encode(any(JwtEncoderParameters.class))).thenAnswer(inv -> {
            var params = (JwtEncoderParameters) inv.getArgument(0);
            return Jwt.withTokenValue(tokenValue)
                    .header("alg", "HS256")
                    .claims(c -> c.putAll(params.getClaims().getClaims()))
                    .issuedAt(Instant.now())
                    .expiresAt(Instant.now().plusSeconds(3600))
                    .build();
        });
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

    @Test
    void loginValidoDevolveTokenNomeEPapel() {
        var user = contaAtiva("fernanda@edu.unifor.br", Role.STUDENT);
        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("sb@2026", user.getPassword())).thenReturn(true);
        encoderDevolve("jwt-assinado");

        AuthToken result = useCaseComToken().execute(user.getEmail(), "sb@2026");

        assertThat(result.token()).isEqualTo("jwt-assinado");
        assertThat(result.fullName()).isEqualTo("Fernanda Lima");
        assertThat(result.role()).isEqualTo("STUDENT");
    }

    /// O scope sai sem o prefixo ROLE_ porque é o que o resource server compara
    /// nas regras de autorização.
    @Test
    void tokenCarregaEmailNoSubjectEPapelNoScope() {
        var admin = contaAtiva("naiara@admin.com", Role.ADMIN);
        when(userRepository.findByEmail(admin.getEmail())).thenReturn(Optional.of(admin));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);
        encoderDevolve("jwt-admin");

        useCaseComToken().execute(admin.getEmail(), "qualquer");

        ArgumentCaptor<JwtEncoderParameters> captor =
                ArgumentCaptor.forClass(JwtEncoderParameters.class);
        verify(jwtEncoder).encode(captor.capture());
        var claims = captor.getValue().getClaims();
        assertThat(claims.getSubject()).isEqualTo("naiara@admin.com");
        assertThat(claims.getClaim("scope").toString()).isEqualTo("ADMIN").doesNotContain("ROLE_");
        assertThat(claims.<String>getClaim("iss")).isEqualTo("smartboarding-api");
        assertThat(claims.getExpiresAt()).isAfter(claims.getIssuedAt());
    }

    /// E-mail inexistente e senha errada devolvem a mesma mensagem: distinguir os
    /// dois casos entregaria de graça quais e-mails existem na base.
    @Test
    void emailInexistenteESenhaErradaFalhamIgual() {
        var user = contaAtiva("fernanda@edu.unifor.br", Role.STUDENT);
        when(userRepository.findByEmail("ninguem@edu.unifor.br")).thenReturn(Optional.empty());
        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        var porEmail = org.assertj.core.api.Assertions.catchThrowable(
                () -> useCaseComToken().execute("ninguem@edu.unifor.br", "x"));
        var porSenha = org.assertj.core.api.Assertions.catchThrowable(
                () -> useCaseComToken().execute(user.getEmail(), "senha-errada"));

        assertThat(porEmail).isInstanceOf(UnauthorizedException.class);
        assertThat(porSenha).isInstanceOf(UnauthorizedException.class);
        assertThat(porEmail.getMessage()).isEqualTo(porSenha.getMessage());
        verify(jwtEncoder, never()).encode(any());
    }

    @Test
    void emailJaCadastradoNaoCriaSegundaConta() {
        var novo = contaAtiva("naiara@admin.com", Role.ADMIN);
        when(userRepository.existsByEmail(novo.getEmail())).thenReturn(true);

        assertThatThrownBy(() -> useCase().execute(novo, "senha123"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining(novo.getEmail());

        verify(userRepository, never()).save(any());
    }

    @Test
    void loadUserByUsernameDevolveOUsuario() {
        var user = contaAtiva("fernanda@edu.unifor.br", Role.STUDENT);
        when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));

        assertThat(useCase().loadUserByUsername(user.getEmail())).isSameAs(user);
    }

    @Test
    void loadUserByUsernameDeDesconhecidoEstoura() {
        when(userRepository.findByEmail("ninguem@edu.unifor.br")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase().loadUserByUsername("ninguem@edu.unifor.br"))
                .isInstanceOf(UsernameNotFoundException.class);
    }
}
