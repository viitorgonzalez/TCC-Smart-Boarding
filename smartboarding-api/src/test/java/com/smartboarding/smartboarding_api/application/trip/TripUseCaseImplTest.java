package com.smartboarding.smartboarding_api.application.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TripUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 8, 6, 30);
    private static final UUID LIST_ID = UUID.randomUUID();
    private static final UUID ROUTE_ID = UUID.randomUUID();
    private static final UUID MAIN_STOP = UUID.randomUUID();
    private static final UUID COMMON_STOP = UUID.randomUUID();

    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock StopRepositoryPort stopRepository;
    @Mock TripCheckpointRepositoryPort checkpointRepository;
    @Mock PublishNotificationUseCase publishNotificationUseCase;

    private TripUseCaseImpl useCase;

    private DailyList listWith(LocalDateTime started, LocalDateTime finished) {
        Route route = Route.builder().id(ROUTE_ID).name("Rota Universitária de Formiga").build();
        return DailyList.builder()
                .id(LIST_ID).route(route).date(LocalDate.of(2026, 9, 8))
                .status(ListStatus.CLOSED)
                .tripStartedAt(started).tripFinishedAt(finished)
                .build();
    }

    @BeforeEach
    void setUp() {
        useCase = new TripUseCaseImpl(dailyListRepository, stopRepository, checkpointRepository,
                publishNotificationUseCase, Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE));
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(null, null)));
        when(dailyListRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(stopRepository.findById(MAIN_STOP)).thenReturn(Optional.of(
                Stop.builder().id(MAIN_STOP).routeId(ROUTE_ID).name("Rodoviária de Pimenta")
                        .sequence(1).isMainPoint(true).build()));
        when(stopRepository.findById(COMMON_STOP)).thenReturn(Optional.of(
                Stop.builder().id(COMMON_STOP).routeId(ROUTE_ID).name("Av. Jair Leite")
                        .sequence(2).isMainPoint(false).build()));
        when(checkpointRepository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void iniciarGravaOInicioEAvisaARota() {
        DailyList saved = useCase.start(LIST_ID);

        assertThat(saved.getTripStartedAt()).isEqualTo(NOW);
        verify(publishNotificationUseCase).publishIndependente(anyString(), anyString(), eq(ROUTE_ID), anyInt(), isNull());
    }

    @Test
    void iniciarDuasVezesEhRecusado() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));

        assertThatThrownBy(() -> useCase.start(LIST_ID))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("já começou");
    }

    @Test
    void checkpointSemTrajetoIniciadoEhRecusado() {
        assertThatThrownBy(() -> useCase.checkpoint(LIST_ID, MAIN_STOP))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("não começou");

        verify(checkpointRepository, never()).save(any());
    }

    @Test
    void checkpointEmParadaComumEhRecusado() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));

        assertThatThrownBy(() -> useCase.checkpoint(LIST_ID, COMMON_STOP))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("ponto principal");

        verify(checkpointRepository, never()).save(any());
    }

    @Test
    void checkpointEmPontoPrincipalGravaEAvisa() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));

        useCase.checkpoint(LIST_ID, MAIN_STOP);

        verify(checkpointRepository).save(any(TripCheckpoint.class));
        verify(publishNotificationUseCase).publishIndependente(anyString(), contains("Rodoviária de Pimenta"),
                eq(ROUTE_ID), anyInt(), isNull());
    }

    @Test
    void checkpointRepetidoNaoDuplicaNemAvisaDeNovo() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));
        when(checkpointRepository.existsByDailyListIdAndStopIdAndLeg(eq(LIST_ID), eq(MAIN_STOP), any()))
                .thenReturn(true);

        useCase.checkpoint(LIST_ID, MAIN_STOP);

        verify(checkpointRepository, never()).save(any());
        verify(publishNotificationUseCase, never()).publishIndependente(any(), any(), any(), any(), any());
    }

    @Test
    void finalizarSemIniciarEhRecusado() {
        assertThatThrownBy(() -> useCase.finish(LIST_ID))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("não começou");
    }

    @Test
    void finalizarGravaOFimEAvisa() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusHours(1), null)));

        DailyList saved = useCase.finish(LIST_ID);

        assertThat(saved.getTripFinishedAt()).isEqualTo(NOW);
        verify(publishNotificationUseCase).publishIndependente(anyString(), anyString(), eq(ROUTE_ID), anyInt(), isNull());
    }

    @Test
    void acaoEmTrajetoJaFinalizadoEhRecusada() {
        when(dailyListRepository.findById(LIST_ID))
                .thenReturn(Optional.of(listWith(NOW.minusHours(2), NOW.minusMinutes(10))));

        assertThatThrownBy(() -> useCase.checkpoint(LIST_ID, MAIN_STOP))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("já terminou");
    }

    @Test
    void paradaDeOutraRotaEhRecusada() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));
        when(stopRepository.findById(MAIN_STOP)).thenReturn(Optional.of(
                Stop.builder().id(MAIN_STOP).routeId(UUID.randomUUID()).name("Outra")
                        .sequence(1).isMainPoint(true).build()));

        assertThatThrownBy(() -> useCase.checkpoint(LIST_ID, MAIN_STOP))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("não é da rota");
    }

    // ─── Ida e volta ──────────────────────────────────────────────────────────

    private static final UUID SEGUNDO_PONTO = UUID.randomUUID();

    /// Dois pontos principais: a ida termina no segundo, e a volta refaz os dois
    /// na ordem inversa.
    private void rotaComDoisPontos() {
        var p1 = Stop.builder().id(MAIN_STOP).routeId(ROUTE_ID).name("Rodoviária")
                .sequence(1).isMainPoint(true).build();
        var p2 = Stop.builder().id(SEGUNDO_PONTO).routeId(ROUTE_ID).name("UNIFOR-MG")
                .sequence(2).isMainPoint(true).build();
        when(stopRepository.findAllByRouteIdOrderBySequenceAsc(ROUTE_ID))
                .thenReturn(java.util.List.of(p1, p2));
        when(stopRepository.findById(SEGUNDO_PONTO)).thenReturn(Optional.of(p2));
        when(stopRepository.findById(MAIN_STOP)).thenReturn(Optional.of(p1));
    }

    private void jaMarcados(TripLeg leg, UUID... stops) {
        when(checkpointRepository.findAllByDailyListId(LIST_ID)).thenReturn(
                java.util.Arrays.stream(stops)
                        .map(id -> TripCheckpoint.builder()
                                .dailyListId(LIST_ID).stopId(id).leg(leg).build())
                        .toList());
    }

    /// O admin ja disse onde esta; pedir uma confirmacao extra pra algo que o
    /// sistema deduz so adicionaria um toque no meio do trajeto.
    @Test
    void marcarOUltimoPontoDaIdaViraAVoltaSozinho() {
        rotaComDoisPontos();
        when(dailyListRepository.findById(LIST_ID))
                .thenReturn(Optional.of(listWith(NOW.minusMinutes(30), null)));
        jaMarcados(TripLeg.OUTBOUND, MAIN_STOP, SEGUNDO_PONTO);

        DailyList result = useCase.checkpoint(LIST_ID, SEGUNDO_PONTO);

        assertThat(result.getOutboundFinishedAt()).isEqualTo(NOW);
        assertThat(result.getTripFinishedAt()).isNull();
    }

    @Test
    void idaIncompletaNaoViraVolta() {
        rotaComDoisPontos();
        when(dailyListRepository.findById(LIST_ID))
                .thenReturn(Optional.of(listWith(NOW.minusMinutes(30), null)));
        jaMarcados(TripLeg.OUTBOUND, MAIN_STOP);

        DailyList result = useCase.checkpoint(LIST_ID, MAIN_STOP);

        assertThat(result.getOutboundFinishedAt()).isNull();
    }

    /// A mesma parada e visitada nas duas pernas. Sem a perna na checagem, o
    /// primeiro checkpoint da volta seria lido como repeticao da ida e ignorado.
    @Test
    void aMesmaParadaEMarcadaDeNovoNaVolta() {
        rotaComDoisPontos();
        var comIdaPronta = listWith(NOW.minusHours(2), null);
        comIdaPronta.setOutboundFinishedAt(NOW.minusMinutes(10));
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(comIdaPronta));
        jaMarcados(TripLeg.RETURN);
        when(checkpointRepository.existsByDailyListIdAndStopIdAndLeg(
                eq(LIST_ID), eq(SEGUNDO_PONTO), eq(TripLeg.RETURN))).thenReturn(false);

        useCase.checkpoint(LIST_ID, SEGUNDO_PONTO);

        var captor = org.mockito.ArgumentCaptor.forClass(TripCheckpoint.class);
        verify(checkpointRepository).save(captor.capture());
        assertThat(captor.getValue().getLeg()).isEqualTo(TripLeg.RETURN);
    }

    @Test
    void marcarOUltimoPontoDaVoltaEncerraODia() {
        rotaComDoisPontos();
        var naVolta = listWith(NOW.minusHours(3), null);
        naVolta.setOutboundFinishedAt(NOW.minusHours(1));
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(naVolta));
        jaMarcados(TripLeg.RETURN, SEGUNDO_PONTO, MAIN_STOP);

        DailyList result = useCase.checkpoint(LIST_ID, MAIN_STOP);

        assertThat(result.getTripFinishedAt()).isEqualTo(NOW);
    }

    @Test
    void avisoDaVoltaSeDistingueDoDaIda() {
        rotaComDoisPontos();
        var naVolta = listWith(NOW.minusHours(3), null);
        naVolta.setOutboundFinishedAt(NOW.minusHours(1));
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(naVolta));
        jaMarcados(TripLeg.RETURN);

        useCase.checkpoint(LIST_ID, MAIN_STOP);

        verify(publishNotificationUseCase).publishIndependente(
                org.mockito.ArgumentMatchers.contains("(volta)"),
                org.mockito.ArgumentMatchers.contains("(volta)"),
                eq(ROUTE_ID), anyInt(), isNull());
    }

    /// Saida pro caso de o onibus nao completar o percurso: encerrar a mao fecha
    /// o dia inteiro, e marca a ida como concluida pra lista nao ficar num
    /// estado impossivel (dia encerrado, ida em aberto).
    @Test
    void encerrarAMaoNoMeioDaIdaFechaAsDuasPernas() {
        when(dailyListRepository.findById(LIST_ID))
                .thenReturn(Optional.of(listWith(NOW.minusMinutes(20), null)));

        DailyList result = useCase.finish(LIST_ID);

        assertThat(result.getTripFinishedAt()).isEqualTo(NOW);
        assertThat(result.getOutboundFinishedAt()).isEqualTo(NOW);
    }

    @Test
    void encerrarAMaoNaVoltaPreservaAHoraRealDaIda() {
        var naVolta = listWith(NOW.minusHours(3), null);
        var fimDaIda = NOW.minusHours(1);
        naVolta.setOutboundFinishedAt(fimDaIda);
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(naVolta));

        DailyList result = useCase.finish(LIST_ID);

        assertThat(result.getOutboundFinishedAt()).isEqualTo(fimDaIda);
        assertThat(result.getTripFinishedAt()).isEqualTo(NOW);
    }

    @Test
    void rotaSemPontoPrincipalNaoTravaNemAvancaSozinha() {
        when(stopRepository.findAllByRouteIdOrderBySequenceAsc(ROUTE_ID))
                .thenReturn(java.util.List.of());
        when(dailyListRepository.findById(LIST_ID))
                .thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));
        jaMarcados(TripLeg.OUTBOUND, MAIN_STOP);

        DailyList result = useCase.checkpoint(LIST_ID, MAIN_STOP);

        assertThat(result.getOutboundFinishedAt()).isNull();
    }

    /// O aviso e melhor esforco DE VERDADE agora: publish comum e @Transactional
    /// REQUIRED, entao uma falha marcaria a transacao do trajeto como
    /// rollback-only e o checkpoint se perderia junto -- engolir a excecao nao
    /// desfaz isso. Por isso o trajeto usa a variante em transacao propria.
    @Test
    void falhaNoAvisoNaoDerrubaOCheckpoint() {
        org.mockito.Mockito.doThrow(new RuntimeException("banco fora"))
                .when(publishNotificationUseCase)
                .publishIndependente(any(), any(), any(), any(), any());

        org.assertj.core.api.Assertions
                .assertThatCode(() -> useCase.start(LIST_ID))
                .doesNotThrowAnyException();
    }
}
