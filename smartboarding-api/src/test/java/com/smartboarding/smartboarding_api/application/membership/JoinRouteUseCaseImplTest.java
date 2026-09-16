package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
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
class JoinRouteUseCaseImplTest {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 11, 10, 0);
    private static final UUID ALUNO = UUID.randomUUID();
    private static final UUID ROTA = UUID.randomUUID();
    /// Instituição que a rota atende — o padrão dos testes que não estão
    /// exercitando o gate de instituição.
    private static final UUID ATENDIDA = UUID.randomUUID();

    @Mock RouteInviteCodeRepositoryPort codeRepository;
    @Mock InstitutionRepositoryPort institutionRepository;
    @Mock RouteMemberRepositoryPort memberRepository;
    @Mock UserInstitutionRepositoryPort userInstitutionRepository;
    @Mock RouteRepositoryPort routeRepository;

    private JoinRouteUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new JoinRouteUseCaseImpl(codeRepository, memberRepository,
                userInstitutionRepository, institutionRepository, routeRepository,
                Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC));
        // Por padrao o aluno ja tem instituicao E a rota a atende; os testes de
        // gate sobrescrevem um ou outro.
        when(userInstitutionRepository.findAllByUserId(any())).thenReturn(List.of(
                UserInstitution.builder().userId(ALUNO)
                        .institutionId(ATENDIDA).build()));
        when(routeRepository.findById(ROTA)).thenReturn(Optional.of(
                Route.builder().id(ROTA).name("Rota Universitária").build()));
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(ATENDIDA).name("UNIFOR-MG").routeId(ROTA).build()));
        when(memberRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(memberRepository.existsByUserIdAndRouteId(any(), any())).thenReturn(false);
    }

    private RouteInviteCode codigo(String code, LocalDateTime expiresAt, LocalDateTime revokedAt) {
        var invite = RouteInviteCode.builder()
                .id(UUID.randomUUID()).routeId(ROTA).code(code)
                .expiresAt(expiresAt).revokedAt(revokedAt).build();
        when(codeRepository.findByCode(code)).thenReturn(Optional.of(invite));
        return invite;
    }

    @Test
    void codigoValidoEntraNaRotaSemAprovacao() {
        var invite = codigo("RU7K2M", AGORA.plusDays(30), null);

        RouteMember member = useCase.join(ALUNO, "RU7K2M");

        assertThat(member.getUserId()).isEqualTo(ALUNO);
        assertThat(member.getRouteId()).isEqualTo(ROTA);
        // Guardar a origem e o que permite contar quantos entraram por cada codigo.
        assertThat(member.getInviteCodeId()).isEqualTo(invite.getId());
    }

    /// O código é digitado à mão: espaço colado e minúscula são erro de digitação,
    /// não código errado.
    @Test
    void codigoEmMinusculaEComEspacoFunciona() {
        codigo("RU7K2M", AGORA.plusDays(30), null);

        assertThat(useCase.join(ALUNO, "  ru7k2m  ").getRouteId()).isEqualTo(ROTA);
    }

    @Test
    void codigoInexistenteERecusado() {
        when(codeRepository.findByCode(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.join(ALUNO, "XXXXXX"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void codigoVazioOuNuloERecusadoAntesDeConsultar() {
        assertThatThrownBy(() -> useCase.join(ALUNO, "   ")).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> useCase.join(ALUNO, null)).isInstanceOf(BadRequestException.class);

        verify(codeRepository, never()).findByCode(any());
    }

    /// Expirado e revogado dão mensagens diferentes de propósito: o aluno precisa
    /// saber se pede código novo ou se errou a digitação.
    @Test
    void codigoExpiradoDizQueExpirou() {
        codigo("RU7K2M", AGORA.minusDays(1), null);

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("expirou");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void codigoRevogadoDizQueFoiCancelado() {
        codigo("RU7K2M", AGORA.plusDays(30), AGORA.minusHours(2));

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("cancelado");
    }

    /// Revogado vence a checagem de prazo: dentro da validade, mas cancelado,
    /// ainda assim não entra.
    @Test
    void revogadoBloqueiaMesmoDentroDoPrazo() {
        codigo("RU7K2M", AGORA.plusDays(30), AGORA.minusHours(2));

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .hasMessageContaining("cancelado");
    }

    /// Entrar duas vezes duplicaria o aluno em toda contagem da lista.
    @Test
    void alunoJaNaRotaNaoEntraDeNovo() {
        codigo("RU7K2M", AGORA.plusDays(30), null);
        when(memberRepository.existsByUserIdAndRouteId(ALUNO, ROTA)).thenReturn(true);

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("já está nessa rota");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void sairRemoveOVinculo() {
        useCase.leave(ALUNO, ROTA);

        verify(memberRepository).deleteByUserIdAndRouteId(ALUNO, ROTA);
    }

    @Test
    void routesOfDevolveTodasAsRotasDoAluno() {
        UUID outra = UUID.randomUUID();
        when(memberRepository.findAllByUserId(ALUNO)).thenReturn(List.of(
                RouteMember.builder().userId(ALUNO).routeId(ROTA).build(),
                RouteMember.builder().userId(ALUNO).routeId(outra).build()));

        assertThat(useCase.routesOf(ALUNO)).containsExactlyInAnyOrder(ROTA, outra);
    }

    @Test
    void alunoSemRotaDevolveListaVazia() {
        when(memberRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThat(useCase.routesOf(ALUNO)).isEmpty();
    }

    /// A instituicao diz onde o aluno desce e em que contagem ele entra. Sem
    /// ela, entraria na lista alguem que o motorista nao sabe onde deixar.
    @Test
    void semInstituicaoNoPerfilNaoEntraEmRota() {
        codigo("RU7K2M", AGORA.plusDays(30), null);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("instituição no perfil");

        verify(memberRepository, never()).save(any());
    }

    /// O gate do perfil rodava antes de consultar o código, pra poupar a
    /// consulta. Deixou de poder: se perfil incompleto barra ou não agora
    /// depende da rota, e a rota só é conhecida pelo código.
    @Test
    void semInstituicaoEmRotaQueExigeInstituicaoRecusa() {
        codigo("RU7K2M", AGORA.plusDays(30), null);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .hasMessageContaining("instituição no perfil");

        verify(memberRepository, never()).save(any());
    }

    /// Código que não existe é recusado antes de qualquer checagem de perfil —
    /// sem rota não há o que conferir.
    @Test
    void codigoInexistenteRecusaAntesDeOlharOPerfil() {
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "NAOEXISTE"))
                .hasMessageContaining("Código inválido");
    }

    @Test
    void comInstituicaoDefinidaEntraNormalmente() {
        codigo("RU7K2M", AGORA.plusDays(30), null);

        assertThat(useCase.join(ALUNO, "RU7K2M").getRouteId()).isEqualTo(ROTA);
    }

    // ─── Código preso a uma instituição ──────────────────────────────────────

    private static final UUID UNIFOR = UUID.randomUUID();
    private static final UUID IFMG = UUID.randomUUID();

    private RouteInviteCode codigoDa(UUID institutionId) {
        var invite = RouteInviteCode.builder()
                .id(UUID.randomUUID()).routeId(ROTA).code("UNI123")
                .expiresAt(AGORA.plusDays(30)).institutionId(institutionId).build();
        when(codeRepository.findByCode("UNI123")).thenReturn(Optional.of(invite));
        return invite;
    }

    private void alunoDe(UUID... institutionIds) {
        when(userInstitutionRepository.findAllByUserId(any())).thenReturn(
                java.util.Arrays.stream(institutionIds)
                        .map(id -> UserInstitution.builder().userId(ALUNO).institutionId(id).build())
                        .toList());
    }

    /// A rota atende estas instituições. Sem declarar, a checagem de rota
    /// recusa antes de chegar na do código.
    private void rotaAtende(UUID... institutionIds) {
        when(institutionRepository.findAll()).thenReturn(
                java.util.Arrays.stream(institutionIds)
                        .map(id -> Institution.builder().id(id)
                                .name("Instituição " + id.toString().substring(0, 4))
                                .routeId(ROTA).build())
                        .toList());
    }

    @Test
    void alunoDaInstituicaoExigidaEntra() {
        codigoDa(UNIFOR);
        rotaAtende(UNIFOR, IFMG);
        alunoDe(UNIFOR);

        assertThat(useCase.join(ALUNO, "UNI123").getRouteId()).isEqualTo(ROTA);
    }

    /// Quem faz dois cursos declara duas instituições: basta o código casar com
    /// uma delas.
    @Test
    void bastaTerAInstituicaoExigidaEntreAsSuas() {
        codigoDa(UNIFOR);
        rotaAtende(UNIFOR, IFMG);
        alunoDe(IFMG, UNIFOR);

        assertThat(useCase.join(ALUNO, "UNI123").getRouteId()).isEqualTo(ROTA);
    }

    @Test
    void alunoDeOutraInstituicaoNaoEntra() {
        codigoDa(UNIFOR);
        rotaAtende(UNIFOR, IFMG);
        alunoDe(IFMG);
        when(institutionRepository.findById(UNIFOR)).thenReturn(Optional.of(
                Institution.builder().id(UNIFOR).name("UNIFOR-MG").build()));

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("UNIFOR-MG");

        verify(memberRepository, never()).save(any());
    }

    /// Nulo é o código aberto: é o que os códigos gerados antes desta regra
    /// continuam sendo, e eles não podem parar de funcionar.
    @Test
    void codigoSemInstituicaoValePraQualquerAluno() {
        codigoDa(null);
        rotaAtende(UNIFOR, IFMG);
        alunoDe(IFMG);

        assertThat(useCase.join(ALUNO, "UNI123").getRouteId()).isEqualTo(ROTA);
    }

    // ─── A rota decide quais instituições entram ─────────────────────────────

    private void rotaAceitaSemInstituicao(boolean aceita) {
        when(routeRepository.findById(ROTA)).thenReturn(Optional.of(
                Route.builder().id(ROTA).name("Rota Universitária")
                        .admitsNoInstitution(aceita).build()));
    }

    /// A lista de instituições atendidas era enfeite: só o código era conferido,
    /// então um código aberto deixava entrar aluno de instituição que aquela
    /// rota nem atende.
    @Test
    void alunoDeInstituicaoQueARotaNaoAtendeNaoEntra() {
        codigoDa(null);
        rotaAtende(UNIFOR);
        alunoDe(IFMG);

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("não atende a sua instituição");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void bastaUmaDasSuasInstituicoesSerAtendida() {
        codigoDa(null);
        rotaAtende(UNIFOR);
        alunoDe(IFMG, UNIFOR);

        assertThat(useCase.join(ALUNO, "UNI123").getRouteId()).isEqualTo(ROTA);
    }

    /// Rota recém-criada ainda não atende ninguém. Recusar é mais honesto que
    /// deixar entrar e o aluno descobrir depois que não aparece em contagem
    /// alguma.
    @Test
    void rotaSemInstituicaoNenhumaRecusa() {
        codigoDa(null);
        rotaAtende();
        alunoDe(UNIFOR);

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("ainda não atende nenhuma instituição");
    }

    @Test
    void semInstituicaoEntraSeARotaAceitar() {
        codigoDa(null);
        rotaAceitaSemInstituicao(true);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThat(useCase.join(ALUNO, "UNI123").getRouteId()).isEqualTo(ROTA);
    }

    /// A chave nasce desligada: deixar entrar sem instituição põe na lista
    /// alguém que o motorista não sabe onde deixar, então é exceção que o
    /// admin abre de propósito.
    @Test
    void porPadraoARotaNaoAceitaSemInstituicao() {
        codigoDa(null);
        rotaAceitaSemInstituicao(false);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .hasMessageContaining("instituição no perfil");
    }

    /// Aceitar sem instituição não afrouxa a regra pra quem TEM uma: continua
    /// valendo que a rota precisa atender a dela.
    @Test
    void aceitarSemInstituicaoNaoLiberaInstituicaoAlheia() {
        codigoDa(null);
        when(routeRepository.findById(ROTA)).thenReturn(Optional.of(
                Route.builder().id(ROTA).name("Rota").admitsNoInstitution(true).build()));
        rotaAtende(UNIFOR);
        alunoDe(IFMG);

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .hasMessageContaining("não atende a sua instituição");
    }

    /// Aceitar sem instituição abre a porta do código ABERTO. Código preso a
    /// uma instituição continua exigindo ela: quem não declarou nenhuma não é
    /// aluno daquela instituição.
    @Test
    void aceitarSemInstituicaoNaoLiberaCodigoDeInstituicao() {
        codigoDa(UNIFOR);
        rotaAceitaSemInstituicao(true);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());
        when(institutionRepository.findById(UNIFOR)).thenReturn(Optional.of(
                Institution.builder().id(UNIFOR).name("UNIFOR-MG").build()));

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .hasMessageContaining("só para alunos de UNIFOR-MG");
    }
}
