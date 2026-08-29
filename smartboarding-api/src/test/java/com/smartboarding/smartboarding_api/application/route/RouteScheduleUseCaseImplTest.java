package com.smartboarding.smartboarding_api.application.route;

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

import java.time.LocalTime;
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

    private RouteScheduleUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new RouteScheduleUseCaseImpl(routeRepository, publishNotificationUseCase);
        Route route = Route.builder()
                .id(ROUTE_ID)
                .name("Rota Universitária de Formiga")
                .openTime(LocalTime.of(0, 0))
                .closeTime(LocalTime.of(16, 0))
                .build();
        when(routeRepository.findById(ROUTE_ID)).thenReturn(Optional.of(route));
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
}
