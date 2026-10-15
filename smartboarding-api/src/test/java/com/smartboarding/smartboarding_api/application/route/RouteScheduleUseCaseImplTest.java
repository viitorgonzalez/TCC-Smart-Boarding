package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
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
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RouteScheduleUseCaseImplTest {

    private static final UUID ROUTE_ID = UUID.randomUUID();

    @Mock RouteRepositoryPort routeRepository;
    @Mock PublishNotificationUseCase publishNotificationUseCase;
    @Mock DailyListRepositoryPort dailyListRepository;

    /// Quarta-feira, 14:00 — dentro de uma janela 00:00–16:00 e fora de uma 00:00–13:00.
    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 10, 14, 14, 0);
    private static final Clock RELOGIO =
            Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
    private Route rota;

    private RouteScheduleUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new RouteScheduleUseCaseImpl(routeRepository, publishNotificationUseCase,
                dailyListRepository, RELOGIO);
        rota = Route.builder()
                .id(ROUTE_ID)
                .name("Rota Universitária de Formiga")
                .openTime(LocalTime.of(0, 0))
                .closeTime(LocalTime.of(16, 0))
                .build();
        when(routeRepository.findById(ROUTE_ID)).thenReturn(Optional.of(rota));
        when(routeRepository.save(any(Route.class))).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void mudarHorarioSemMotivoEhRecusado() {
        assertThatThrownBy(() -> useCase.execute(ROUTE_ID, LocalTime.of(5, 30), LocalTime.of(16, 0), "  "))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("motivo");

        verify(routeRepository, never()).save(any());
        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    @Test
    void mudarHorarioAvisaARota() {
        Route saved = useCase.execute(ROUTE_ID, LocalTime.of(5, 30), LocalTime.of(17, 0),
                "Horário de aula mudou.");

        assertThat(saved.getOpenTime()).isEqualTo(LocalTime.of(5, 30));
        assertThat(saved.getCloseTime()).isEqualTo(LocalTime.of(17, 0));
        verify(publishNotificationUseCase).publish(
                eq("Horário da lista mudou"), contains("05:30"), eq(ROUTE_ID), anyInt(), isNull());
    }

    @Test
    void salvarOsMesmosHorariosNaoAvisaNinguem() {
        useCase.execute(ROUTE_ID, LocalTime.of(0, 0), LocalTime.of(16, 0), null);

        verify(routeRepository, never()).save(any());
        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    @Test
    void fechamentoAntesDaAberturaEhRecusado() {
        assertThatThrownBy(() -> useCase.execute(ROUTE_ID, LocalTime.of(18, 0), LocalTime.of(6, 0), "qualquer"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("abrir antes");
    }

    private DailyList listaDeHoje(ListStatus status, boolean manual) {
        DailyList list = DailyList.builder()
                .id(UUID.randomUUID())
                .route(rota)
                .date(AGORA.toLocalDate())
                .status(status)
                .manualOverride(manual)
                .closedAt(status == ListStatus.CLOSED ? AGORA.minusHours(1) : null)
                .build();
        when(dailyListRepository.findByRouteIdAndDate(ROUTE_ID, AGORA.toLocalDate()))
                .thenReturn(Optional.of(list));
        when(dailyListRepository.save(any(DailyList.class))).thenAnswer(i -> i.getArgument(0));
        return list;
    }

    @Test
    void esticarOHorarioReabreAListaQueJaTinhaFechado() {
        DailyList lista = listaDeHoje(ListStatus.CLOSED, false);

        useCase.execute(ROUTE_ID, LocalTime.of(0, 0), LocalTime.of(19, 0), "Ônibus atrasou");

        assertThat(lista.getStatus()).isEqualTo(ListStatus.OPEN);
        assertThat(lista.getClosedAt()).isNull();
        verify(dailyListRepository).save(lista);
    }

    @Test
    void adiantarOFechamentoFechaAListaAbertaNaHora() {
        DailyList lista = listaDeHoje(ListStatus.OPEN, false);

        useCase.execute(ROUTE_ID, LocalTime.of(0, 0), LocalTime.of(13, 0), "Viagem cancelada");

        assertThat(lista.getStatus()).isEqualTo(ListStatus.CLOSED);
        assertThat(lista.getClosedAt()).isEqualTo(AGORA);
    }

    @Test
    void mudarOHorarioCancelaOOverrideManual() {
        DailyList lista = listaDeHoje(ListStatus.CLOSED, true);

        useCase.execute(ROUTE_ID, LocalTime.of(0, 0), LocalTime.of(19, 0), "Ônibus atrasou");

        assertThat(lista.isManualOverride()).isFalse();
        assertThat(lista.getStatus()).isEqualTo(ListStatus.OPEN);
    }

    @Test
    void listaJaCoerenteComOHorarioNovoNaoEhTocada() {
        listaDeHoje(ListStatus.OPEN, false);

        useCase.execute(ROUTE_ID, LocalTime.of(0, 0), LocalTime.of(19, 0), "Ajuste");

        verify(dailyListRepository, never()).save(any(DailyList.class));
    }

    @Test
    void semListaHojeAMudancaNaoEstoura() {
        when(dailyListRepository.findByRouteIdAndDate(ROUTE_ID, AGORA.toLocalDate()))
                .thenReturn(Optional.empty());

        assertThat(useCase.execute(ROUTE_ID, LocalTime.of(0, 0), LocalTime.of(19, 0), "Ajuste"))
                .isNotNull();
        verify(dailyListRepository, never()).save(any(DailyList.class));
    }
}
