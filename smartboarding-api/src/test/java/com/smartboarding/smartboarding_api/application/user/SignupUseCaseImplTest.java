package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

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
class SignupUseCaseImplTest {

    @Mock UserRepositoryPort userRepository;
    @Mock PasswordEncoder passwordEncoder;

    private SignupUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new SignupUseCaseImpl(userRepository, passwordEncoder);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(userRepository.existsByEmail(any())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$hash");
    }

    private User novo() {
        return User.builder().email("fernanda@edu.unifor.br").fullName("Fernanda Lima").build();
    }

    @Test
    void contaNasceAtivaComSenhaCifrada() {
        User saved = useCase.signup(novo(), "sb@2026");

        assertThat(saved.isActive()).isTrue();
        assertThat(saved.getPassword()).isEqualTo("$2a$10$hash");
        assertThat(saved.getPassword()).isNotEqualTo("sb@2026");
    }

    /// O endpoint e publico. Aceitar o papel do request deixaria qualquer um
    /// criar conta de admin por ele.
    @Test
    void papelEsempreStudentMesmoSePedirAdmin() {
        User tentativa = novo();
        tentativa.setRole(Role.ADMIN);

        assertThat(useCase.signup(tentativa, "sb@2026").getRole()).isEqualTo(Role.STUDENT);
    }

    /// A conta nasce sem rota: o acesso vem depois, pelo codigo de convite. Se
    /// nascesse com rota, o codigo nao serviria pra nada.
    @Test
    void contaNasceSemRotaEInstituicaoEOpcional() {
        User saved = useCase.signup(novo(), "sb@2026");

        assertThat(saved.getInstitutionId()).isNull();
    }

    @Test
    void instituicaoInformadaEPreservada() {
        UUID inst = UUID.randomUUID();
        User com = novo();
        com.setInstitutionId(inst);

        assertThat(useCase.signup(com, "sb@2026").getInstitutionId()).isEqualTo(inst);
    }

    /// Login e recuperacao de senha respondem igual havendo conta ou nao. Aqui e
    /// o oposto de proposito: fingir sucesso deixaria o aluno achando que criou
    /// conta nova, sem conseguir entrar e sem entender por que.
    @Test
    void emailJaCadastradoAvisaEmVezDeFingirSucesso() {
        when(userRepository.existsByEmail("fernanda@edu.unifor.br")).thenReturn(true);

        assertThatThrownBy(() -> useCase.signup(novo(), "sb@2026"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("já tem conta");

        verify(userRepository, never()).save(any());
    }

    @Test
    void senhaCrurNuncaChegaNoRepositorio() {
        useCase.signup(novo(), "sb@2026");

        var captor = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getPassword()).doesNotContain("sb@2026");
        verify(passwordEncoder).encode("sb@2026");
    }
}
