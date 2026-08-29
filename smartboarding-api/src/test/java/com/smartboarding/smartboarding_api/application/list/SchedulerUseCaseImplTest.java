package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.report.port.in.GenerateReportUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SchedulerUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDate FRIDAY = LocalDate.of(2026, 8, 28);
    private static final LocalDate SATURDAY = LocalDate.of(2026, 8, 29);
    private static final UUID ROUTE_ID = UUID.randomUUID();

    @Mock RouteRepositoryPort routeRepository;
    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock GenerateReportUseCase generateReportUseCase;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock SendToUserUseCase sendToUserUseCase;
    @Mock PublishNotificationUseCase publishNotificationUseCase;

    private SchedulerUseCaseImpl schedulerAt(LocalDate date, LocalTime time) {
        Clock clock = Clock.fixed(date.atTime(time).atZone(ZONE).toInstant(), ZONE);
        return new SchedulerUseCaseImpl(routeRepository, dailyListRepository,
                generateReportUseCase, listEntryRepository, sendToUserUseCase,
                publishNotificationUseCase, clock);
    }

    private void routeOpeningAt(LocalTime openTime) {
        Route route = Route.builder()
                .id(ROUTE_ID)
                .name("Rota Universitária de Formiga")
                .openTime(openTime)
                .closeTime(LocalTime.of(16, 0))
                .isActive(true)
                .build();
        when(routeRepository.findAllByIsActiveTrue()).thenReturn(List.of(route));
    }

    @Test
    void naoAbreAntesDoHorarioDaRota() {
        routeOpeningAt(LocalTime.of(5, 30));

        schedulerAt(FRIDAY, LocalTime.of(5, 0)).open();

        verify(dailyListRepository, never()).save(any());
    }

    @Test
    void abreQuandoChegaOHorarioDaRota() {
        routeOpeningAt(LocalTime.of(5, 30));
        when(dailyListRepository.existsByRouteIdAndDate(ROUTE_ID, FRIDAY)).thenReturn(false);

        schedulerAt(FRIDAY, LocalTime.of(5, 30)).open();

        verify(dailyListRepository).save(any(DailyList.class));
    }

    @Test
    void abrirALitaAvisaARota() {
        routeOpeningAt(LocalTime.of(5, 30));
        when(dailyListRepository.existsByRouteIdAndDate(ROUTE_ID, FRIDAY)).thenReturn(false);

        schedulerAt(FRIDAY, LocalTime.of(5, 30)).open();

        verify(publishNotificationUseCase).publish(
                eq("Lista de hoje aberta"), anyString(), eq(ROUTE_ID), anyInt(), isNull());
    }

    @Test
    void naoDuplicaListaJaCriadaNaVarreduraAnterior() {
        routeOpeningAt(LocalTime.of(5, 30));
        when(dailyListRepository.existsByRouteIdAndDate(ROUTE_ID, FRIDAY)).thenReturn(true);

        schedulerAt(FRIDAY, LocalTime.of(9, 0)).open();

        verify(dailyListRepository, never()).save(any());
    }

    @Test
    void naoFechaListaQueOAdminReabriuNaMao() {
        Route route = Route.builder()
                .id(ROUTE_ID)
                .name("Rota Universitária de Formiga")
                .openTime(LocalTime.of(5, 30))
                .closeTime(LocalTime.of(16, 0))
                .isActive(true)
                .build();
        DailyList reopened = DailyList.builder()
                .id(UUID.randomUUID())
                .route(route)
                .date(FRIDAY)
                .status(ListStatus.OPEN)
                .manualOverride(true)
                .build();
        when(dailyListRepository.findAllByStatus(ListStatus.OPEN)).thenReturn(List.of(reopened));

        schedulerAt(FRIDAY, LocalTime.of(17, 0)).close();

        verify(dailyListRepository, never()).save(any());
    }

    @Test
    void fechaListaDeDiaPassadoMesmoComOverride() {
        Route route = Route.builder()
                .id(ROUTE_ID)
                .name("Rota Universitária de Formiga")
                .openTime(LocalTime.of(5, 30))
                .closeTime(LocalTime.of(16, 0))
                .isActive(true)
                .build();
        DailyList stale = DailyList.builder()
                .id(UUID.randomUUID())
                .route(route)
                .date(FRIDAY.minusDays(1))
                .status(ListStatus.OPEN)
                .manualOverride(true)
                .build();
        when(dailyListRepository.findAllByStatus(ListStatus.OPEN)).thenReturn(List.of(stale));

        schedulerAt(FRIDAY, LocalTime.of(9, 0)).close();

        verify(dailyListRepository).save(any(DailyList.class));
    }

    @Test
    void naoAbreNoFimDeSemana() {
        routeOpeningAt(LocalTime.of(5, 30));

        schedulerAt(SATURDAY, LocalTime.of(9, 0)).open();

        verify(dailyListRepository, never()).save(any());
        verify(routeRepository, never()).findAllByIsActiveTrue();
    }
}
