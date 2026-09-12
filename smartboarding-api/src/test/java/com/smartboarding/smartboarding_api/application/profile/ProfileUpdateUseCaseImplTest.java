package com.smartboarding.smartboarding_api.application.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateStatus;
import com.smartboarding.smartboarding_api.domain.profile.port.out.ProfileUpdateRequestRepositoryPort;
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

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
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
class ProfileUpdateUseCaseImplTest {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 12, 10, 0);
    private static final UUID ALUNO = UUID.randomUUID();
    private static final UUID ADMIN = UUID.randomUUID();

    @Mock ProfileUpdateRequestRepositoryPort requestRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase
            userInstitutions;

    private ProfileUpdateUseCaseImpl useCase;
    private User aluno;

    @BeforeEach
    void setUp() {
        useCase = new ProfileUpdateUseCaseImpl(requestRepository, userRepository, userInstitutions,
                Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC));
        aluno = User.builder().id(ALUNO).email("fernanda@edu.unifor.br")
                .fullName("Fernanda Lima").phone("37999990000")
                .course("Engenharia").address("Rua A, 1").build();
        when(userRepository.findById(ALUNO)).thenReturn(Optional.of(aluno));
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(requestRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(requestRepository.findPendingByUserId(any())).thenReturn(Optional.empty());
    }

    private ProfileUpdateRequest pedidoDe(UUID id, ProfileUpdateStatus status) {
        var p = ProfileUpdateRequest.builder().id(id).userId(ALUNO)
                .fullName("Fernanda Lima Souza").status(status).build();
        when(requestRepository.findById(id)).thenReturn(Optional.of(p));
        return p;
    }

    @Test
    void pedidoNasceePendenteEAmarradoAoUsuarioDoToken() {
        var p = useCase.request(ALUNO,
                ProfileUpdateRequest.builder().phone("37988887777").build());

        assertThat(p.getStatus()).isEqualTo(ProfileUpdateStatus.PENDING);
        assertThat(p.getUserId()).isEqualTo(ALUNO);
    }

    /// Nada muda no perfil enquanto o admin nao aprova -- e o ponto do fluxo.
    @Test
    void abrirPedidoNaoTocaNoPerfil() {
        useCase.request(ALUNO, ProfileUpdateRequest.builder().fullName("Outro Nome").build());

        assertThat(aluno.getFullName()).isEqualTo("Fernanda Lima");
        verify(userRepository, never()).save(any());
    }

    @Test
    void pedidoSemNenhumCampoERecusado() {
        assertThatThrownBy(() -> useCase.request(ALUNO, ProfileUpdateRequest.builder().build()))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("ao menos um campo");

        verify(requestRepository, never()).save(any());
    }

    /// Com dois pendentes o admin aprovaria um sem saber do outro, e o segundo
    /// sobrescreveria o primeiro sem revisao.
    @Test
    void segundoPedidoPendenteEBloqueado() {
        when(requestRepository.findPendingByUserId(ALUNO)).thenReturn(
                Optional.of(ProfileUpdateRequest.builder().userId(ALUNO).build()));

        assertThatThrownBy(() -> useCase.request(ALUNO,
                ProfileUpdateRequest.builder().phone("37988887777").build()))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("em análise");
    }

    @Test
    void usuarioInexistenteNaoAbrePedido() {
        UUID desconhecido = UUID.randomUUID();
        when(userRepository.findById(desconhecido)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.request(desconhecido,
                ProfileUpdateRequest.builder().phone("x").build()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void aprovarAplicaOsCamposPedidos() {
        var p = pedidoDe(UUID.randomUUID(), ProfileUpdateStatus.PENDING);
        p.setPhone("37988887777");
        p.setBirthDate(LocalDate.of(2004, 5, 10));

        var aprovado = useCase.approve(p.getId(), ADMIN);

        assertThat(aluno.getFullName()).isEqualTo("Fernanda Lima Souza");
        assertThat(aluno.getPhone()).isEqualTo("37988887777");
        assertThat(aluno.getBirthDate()).isEqualTo(LocalDate.of(2004, 5, 10));
        assertThat(aprovado.getStatus()).isEqualTo(ProfileUpdateStatus.APPROVED);
        assertThat(aprovado.getReviewedBy()).isEqualTo(ADMIN);
        assertThat(aprovado.getReviewedAt()).isEqualTo(AGORA);
    }

    /// Campo nulo = nao foi pedida mudanca nele. Aplicar tudo sobrescreveria com
    /// null o que o aluno nao quis mexer.
    @Test
    void campoNaoPedidoNaoEApagado() {
        var p = pedidoDe(UUID.randomUUID(), ProfileUpdateStatus.PENDING);

        useCase.approve(p.getId(), ADMIN);

        assertThat(aluno.getPhone()).isEqualTo("37999990000");
        assertThat(aluno.getCourse()).isEqualTo("Engenharia");
        assertThat(aluno.getAddress()).isEqualTo("Rua A, 1");
    }

    @Test
    void recusarExigeMotivoEGuardaOTexto() {
        var p = pedidoDe(UUID.randomUUID(), ProfileUpdateStatus.PENDING);

        assertThatThrownBy(() -> useCase.reject(p.getId(), "  ", ADMIN))
                .isInstanceOf(BadRequestException.class);

        var recusado = useCase.reject(p.getId(), "  Nome não confere com o documento  ", ADMIN);

        assertThat(recusado.getStatus()).isEqualTo(ProfileUpdateStatus.REJECTED);
        assertThat(recusado.getRejectionReason()).isEqualTo("Nome não confere com o documento");
        assertThat(aluno.getFullName()).isEqualTo("Fernanda Lima");
    }

    /// Decidir duas vezes aplicaria a mudanca de novo ou apagaria o registro de
    /// quem decidiu antes.
    @Test
    void pedidoJaAnalisadoNaoEDecididoDeNovo() {
        var aprovado = pedidoDe(UUID.randomUUID(), ProfileUpdateStatus.APPROVED);

        assertThatThrownBy(() -> useCase.approve(aprovado.getId(), ADMIN))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("já foi analisada");
        assertThatThrownBy(() -> useCase.reject(aprovado.getId(), "motivo", ADMIN))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void pedidoInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(requestRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.approve(id, ADMIN)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void alunoApagadoEntreOPedidoEAAprovacaoNaoQuebra() {
        var p = pedidoDe(UUID.randomUUID(), ProfileUpdateStatus.PENDING);
        when(userRepository.findById(ALUNO)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.approve(p.getId(), ADMIN))
                .isInstanceOf(NotFoundException.class);
    }

    /// users.institution_id e derivado de user_institutions por um unico
    /// escritor. Gravando direto na aprovacao, o campo apontava pra uma
    /// instituicao sem linha na tabela -- e o proximo add/remove no perfil
    /// recalculava e desfazia a aprovacao do admin, sem aviso nenhum.
    @Test
    void aprovarInstituicaoCriaOVinculoEmVezDeGravarOCampo() {
        UUID novaInstituicao = UUID.randomUUID();
        ProfileUpdateRequest pedido = ProfileUpdateRequest.builder()
                .id(UUID.randomUUID()).userId(ALUNO).institutionId(novaInstituicao)
                .status(ProfileUpdateStatus.PENDING).build();
        when(requestRepository.findById(pedido.getId())).thenReturn(Optional.of(pedido));
        when(userInstitutions.institutionsOf(ALUNO)).thenReturn(java.util.List.of());

        useCase.approve(pedido.getId(), ADMIN);

        org.mockito.Mockito.verify(userInstitutions).add(ALUNO, novaInstituicao);
        assertThat(aluno.getInstitutionId()).isNull();
    }

    /// Aprovar duas vezes, ou aprovar instituicao que o aluno ja declarou, nao
    /// pode estourar: o add() recusa vinculo repetido com 409.
    @Test
    void aprovarInstituicaoJaVinculadaNaoQuebra() {
        UUID jaTem = UUID.randomUUID();
        ProfileUpdateRequest pedido = ProfileUpdateRequest.builder()
                .id(UUID.randomUUID()).userId(ALUNO).institutionId(jaTem)
                .status(ProfileUpdateStatus.PENDING).build();
        when(requestRepository.findById(pedido.getId())).thenReturn(Optional.of(pedido));
        when(userInstitutions.institutionsOf(ALUNO)).thenReturn(java.util.List.of(jaTem));

        useCase.approve(pedido.getId(), ADMIN);

        org.mockito.Mockito.verify(userInstitutions, org.mockito.Mockito.never()).add(any(), any());
    }

    /// O admin e obrigado a escrever o motivo da recusa justamente pro aluno
    /// ler. Com myPending (so PENDING), ele nunca chegava la.
    @Test
    void oUltimoPedidoDevolveARecusaComOMotivo() {
        ProfileUpdateRequest recusado = ProfileUpdateRequest.builder()
                .id(UUID.randomUUID()).userId(ALUNO)
                .status(ProfileUpdateStatus.REJECTED).rejectionReason("Curso não confere")
                .build();
        when(requestRepository.findAllByUserId(ALUNO)).thenReturn(java.util.List.of(recusado));

        assertThat(useCase.myLatest(ALUNO)).get()
                .extracting(ProfileUpdateRequest::getRejectionReason)
                .isEqualTo("Curso não confere");
    }
}
