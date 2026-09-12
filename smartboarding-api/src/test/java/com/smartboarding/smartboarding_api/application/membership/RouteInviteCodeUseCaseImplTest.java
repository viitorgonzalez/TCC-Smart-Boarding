package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
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
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RouteInviteCodeUseCaseImplTest {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 11, 10, 0);
    private static final UUID ROTA = UUID.randomUUID();
    private static final UUID ADMIN = UUID.randomUUID();
    private static final int TAMANHO = 6;
    private static final long VALIDADE_DIAS = 90;

    @Mock RouteInviteCodeRepositoryPort codeRepository;
    @Mock RouteMemberRepositoryPort memberRepository;
    @Mock RouteRepositoryPort routeRepository;

    private RouteInviteCodeUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new RouteInviteCodeUseCaseImpl(codeRepository, memberRepository, routeRepository,
                Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC), TAMANHO, VALIDADE_DIAS);
        when(routeRepository.findById(ROTA)).thenReturn(Optional.of(
                Route.builder().id(ROTA).name("Rota Universitária").build()));
        when(codeRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(codeRepository.existsByCode(any())).thenReturn(false);
    }

    @Test
    void semExpiracaoUsaAValidadePadrao() {
        RouteInviteCode code = useCase.generate(ROTA, null, ADMIN);

        assertThat(code.getExpiresAt()).isEqualTo(AGORA.plusDays(VALIDADE_DIAS));
        assertThat(code.getRouteId()).isEqualTo(ROTA);
        assertThat(code.getCreatedBy()).isEqualTo(ADMIN);
        assertThat(code.getRevokedAt()).isNull();
    }

    @Test
    void expiracaoInformadaERespeitada() {
        var prazo = AGORA.plusDays(7);

        assertThat(useCase.generate(ROTA, prazo, ADMIN).getExpiresAt()).isEqualTo(prazo);
    }

    /// Código que já nasce vencido não serve pra nada e o admin só descobriria
    /// quando um aluno reclamasse.
    @Test
    void expiracaoNoPassadoERecusada() {
        assertThatThrownBy(() -> useCase.generate(ROTA, AGORA.minusDays(1), ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("futuro");

        verify(codeRepository, never()).save(any());
    }

    @Test
    void expiracaoExatamenteAgoraERecusada() {
        assertThatThrownBy(() -> useCase.generate(ROTA, AGORA, ADMIN))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void rotaInexistenteNaoGeraCodigo() {
        UUID desconhecida = UUID.randomUUID();
        when(routeRepository.findById(desconhecida)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.generate(desconhecida, null, ADMIN))
                .isInstanceOf(NotFoundException.class);

        verify(codeRepository, never()).save(any());
    }

    /// O código é lido em voz alta e copiado do quadro: O/0, I/1 e L fora do
    /// alfabeto evitam o erro de digitação clássico.
    @Test
    void codigoNaoUsaCaracteresAmbiguos() {
        var gerados = IntStream.range(0, 200)
                .mapToObj(i -> useCase.generate(ROTA, null, ADMIN).getCode())
                .toList();

        assertThat(gerados).allSatisfy(c -> {
            assertThat(c).hasSize(TAMANHO);
            assertThat(c).doesNotContain("O").doesNotContain("0");
            assertThat(c).doesNotContain("I").doesNotContain("1").doesNotContain("L");
            assertThat(c).matches("[A-Z2-9]+");
        });
    }

    /// O código é UNIQUE no banco: sem o retry, o azar viraria 500 na cara do admin.
    @Test
    void colisaoDeCodigoGeraOutroEmVezDeFalhar() {
        when(codeRepository.existsByCode(any())).thenReturn(true, true, false);

        assertThat(useCase.generate(ROTA, null, ADMIN).getCode()).isNotBlank();

        verify(codeRepository, org.mockito.Mockito.times(3)).existsByCode(any());
    }

    @Test
    void revogarMarcaAHoraDaRevogacao() {
        var code = RouteInviteCode.builder().id(UUID.randomUUID()).routeId(ROTA)
                .code("RU7K2M").expiresAt(AGORA.plusDays(30)).build();
        when(codeRepository.findById(code.getId())).thenReturn(Optional.of(code));

        assertThat(useCase.revoke(code.getId()).getRevokedAt()).isEqualTo(AGORA);
    }

    /// Clicar duas vezes em revogar não é erro: o resultado que o admin quer já
    /// está valendo, e sobrescrever a data apagaria quando foi de verdade.
    @Test
    void revogarDuasVezesMantemAPrimeiraData() {
        var revogadoAntes = AGORA.minusDays(2);
        var code = RouteInviteCode.builder().id(UUID.randomUUID()).routeId(ROTA)
                .code("RU7K2M").expiresAt(AGORA.plusDays(30)).revokedAt(revogadoAntes).build();
        when(codeRepository.findById(code.getId())).thenReturn(Optional.of(code));

        assertThat(useCase.revoke(code.getId()).getRevokedAt()).isEqualTo(revogadoAntes);
        verify(codeRepository, never()).save(any());
    }

    @Test
    void revogarCodigoInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(codeRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.revoke(id)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void listarFiltraPelaRota() {
        var lista = List.of(RouteInviteCode.builder().routeId(ROTA).build());
        when(codeRepository.findAllByRouteId(ROTA)).thenReturn(lista);

        assertThat(useCase.listByRoute(ROTA)).isEqualTo(lista);
    }

    @Test
    void contagemDeUsosVemDosVinculosDaqueleCodigo() {
        UUID codeId = UUID.randomUUID();
        when(memberRepository.countByInviteCodeId(codeId)).thenReturn(23L);

        assertThat(useCase.countUses(codeId)).isEqualTo(23L);
    }
}
