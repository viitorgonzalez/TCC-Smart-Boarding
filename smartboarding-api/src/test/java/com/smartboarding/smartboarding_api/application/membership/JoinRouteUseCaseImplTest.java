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
        assertThat(member.getInviteCodeId()).isEqualTo(invite.getId());
    }

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

    @Test
    void revogadoBloqueiaMesmoDentroDoPrazo() {
        codigo("RU7K2M", AGORA.plusDays(30), AGORA.minusHours(2));

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .hasMessageContaining("cancelado");
    }

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

    @Test
    void semInstituicaoNoPerfilNaoEntraEmRota() {
        codigo("RU7K2M", AGORA.plusDays(30), null);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("instituição no perfil");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void semInstituicaoEmRotaQueExigeInstituicaoRecusa() {
        codigo("RU7K2M", AGORA.plusDays(30), null);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .hasMessageContaining("instituição no perfil");

        verify(memberRepository, never()).save(any());
    }

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

    @Test
    void codigoSemInstituicaoValePraQualquerAluno() {
        codigoDa(null);
        rotaAtende(UNIFOR, IFMG);
        alunoDe(IFMG);

        assertThat(useCase.join(ALUNO, "UNI123").getRouteId()).isEqualTo(ROTA);
    }

    private void rotaAceitaSemInstituicao(boolean aceita) {
        when(routeRepository.findById(ROTA)).thenReturn(Optional.of(
                Route.builder().id(ROTA).name("Rota Universitária")
                        .admitsNoInstitution(aceita).build()));
    }

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

    @Test
    void porPadraoARotaNaoAceitaSemInstituicao() {
        codigoDa(null);
        rotaAceitaSemInstituicao(false);
        when(userInstitutionRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThatThrownBy(() -> useCase.join(ALUNO, "UNI123"))
                .hasMessageContaining("instituição no perfil");
    }

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
