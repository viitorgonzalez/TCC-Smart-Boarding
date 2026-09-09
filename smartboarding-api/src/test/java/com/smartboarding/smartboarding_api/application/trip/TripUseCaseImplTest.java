package com.smartboarding.smartboarding_api.application.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
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
        verify(publishNotificationUseCase).publish(anyString(), anyString(), eq(ROUTE_ID), anyInt(), isNull());
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
        verify(publishNotificationUseCase).publish(anyString(), contains("Rodoviária de Pimenta"),
                eq(ROUTE_ID), anyInt(), isNull());
    }

    @Test
    void checkpointRepetidoNaoDuplicaNemAvisaDeNovo() {
        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(listWith(NOW.minusMinutes(5), null)));
        when(checkpointRepository.existsByDailyListIdAndStopId(LIST_ID, MAIN_STOP)).thenReturn(true);

        useCase.checkpoint(LIST_ID, MAIN_STOP);

        verify(checkpointRepository, never()).save(any());
        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
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
        verify(publishNotificationUseCase).publish(anyString(), anyString(), eq(ROUTE_ID), anyInt(), isNull());
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
}
