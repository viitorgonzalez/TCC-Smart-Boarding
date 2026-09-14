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
        useCase = comBootstrap("");
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(userRepository.existsByEmail(any())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$hash");
    }

    /// Política de verdade, não mock: o que estes testes precisam provar é o
    /// papel com que a conta nasce, e um mock da política só provaria que o caso
    /// de uso repassa a chamada.
    private SignupUseCaseImpl comBootstrap(String bootstrapAdminEmail) {
        return new SignupUseCaseImpl(userRepository, passwordEncoder,
                new BootstrapAdminPolicy(userRepository, bootstrapAdminEmail));
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

    /// Banco novo nao tem admin, logo nao ha quem promova. A variavel concede --
    /// nao cria conta: a pessoa ainda se cadastra sozinha.
    @Test
    void oPrimeiroCadastroComOEmailDeBootstrapNasceAdmin() {
        SignupUseCaseImpl useCaseComBootstrap = comBootstrap("chefe@prefeitura.gov.br");
        when(userRepository.countAdmins()).thenReturn(0L);

        User criado = useCaseComBootstrap.signup(
                User.builder().email("chefe@prefeitura.gov.br").fullName("Chefe").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.ADMIN);
    }

    /// A janela fecha sozinha: existindo admin, a condicao nunca mais e
    /// verdadeira, mesmo com a variavel configurada pra sempre.
    @Test
    void comAdminExistenteOBootstrapNaoVale() {
        SignupUseCaseImpl useCaseComBootstrap = comBootstrap("chefe@prefeitura.gov.br");
        when(userRepository.countAdmins()).thenReturn(1L);

        User criado = useCaseComBootstrap.signup(
                User.builder().email("chefe@prefeitura.gov.br").fullName("Chefe").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
    }

    @Test
    void outroEmailNaoVirapAdminNemComZeroAdmins() {
        SignupUseCaseImpl useCaseComBootstrap = comBootstrap("chefe@prefeitura.gov.br");

        User criado = useCaseComBootstrap.signup(
                User.builder().email("outra@pessoa.com").fullName("Outra").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
    }

    /// Sem a variavel configurada -- o caso normal -- nada de especial acontece,
    /// e nem se consulta o banco por admin.
    @Test
    void semVariavelConfiguradaNinguemNasceAdmin() {
        SignupUseCaseImpl semBootstrap = comBootstrap("");

        User criado = semBootstrap.signup(
                User.builder().email("qualquer@pessoa.com").fullName("Qualquer").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
        verify(userRepository, org.mockito.Mockito.never()).countAdmins();
    }

    /// A unicidade de `email` no Postgres é case-sensitive e nada normaliza o
    /// valor antes de gravar. Com comparação sem caixa, CHEFE@... e chefe@...
    /// seriam contas DISTINTAS e ambas satisfariam a mesma janela: o atacante
    /// levaria uma grafia, o cadastro legítimo sucederia como STUDENT sem
    /// conflito nenhum, e nada sinalizaria que a janela foi consumida.
    @Test
    void grafiaComOutraCaixaNaoCasaComOEmailDeBootstrap() {
        SignupUseCaseImpl useCaseComBootstrap = comBootstrap("chefe@prefeitura.gov.br");
        when(userRepository.countAdmins()).thenReturn(0L);

        User criado = useCaseComBootstrap.signup(
                User.builder().email("CHEFE@prefeitura.gov.br").fullName("Impostor").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
    }
}
