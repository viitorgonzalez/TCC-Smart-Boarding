package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.route.port.out.GeoPoint;
import com.smartboarding.smartboarding_api.domain.route.port.out.RoutePlannerPort;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RouteTimingUseCaseImplTest {

    private static final UUID ROTA = UUID.randomUUID();

    @Mock StopRepositoryPort stopRepository;
    @Mock RoutePlannerPort planner;

    private RouteTimingUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new RouteTimingUseCaseImpl(stopRepository, planner);
        when(stopRepository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    private Stop parada(String nome, int seq, Double lat, Double lon) {
        return Stop.builder().id(UUID.randomUUID()).routeId(ROTA).name(nome)
                .sequence(seq).latitude(lat).longitude(lon).build();
    }

    private List<Stop> comParadas(Stop... stops) {
        var lista = List.of(stops);
        when(stopRepository.findAllByRouteIdOrderBySequenceAsc(ROTA)).thenReturn(lista);
        return lista;
    }

    @Test
    void somaUmMinutoDeEmbarquePorParada() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var b = parada("Centro", 2, -20.47, -45.43);
        var c = parada("UNIFOR-MG", 3, -20.48, -45.44);
        comParadas(a, b, c);
        when(planner.legDurationsSeconds(any()))
                .thenReturn(Optional.of(List.of(300.0, 300.0)));

        useCase.recalculate(ROTA);

        assertThat(a.getAvgMinutesFromStart()).isEqualTo(1);
        assertThat(b.getAvgMinutesFromStart()).isEqualTo(7);
        assertThat(c.getAvgMinutesFromStart()).isEqualTo(13);
    }

    @Test
    void osrmIndisponivelDeixaOTempoNulo() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var b = parada("Centro", 2, -20.47, -45.43);
        a.setAvgMinutesFromStart(5);
        b.setAvgMinutesFromStart(9);
        comParadas(a, b);
        when(planner.legDurationsSeconds(any())).thenReturn(Optional.empty());

        useCase.recalculate(ROTA);

        assertThat(a.getAvgMinutesFromStart()).isNull();
        assertThat(b.getAvgMinutesFromStart()).isNull();
    }

    @Test
    void paradaSemCoordenadaNaoVaiProPlanejador() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var semCoord = parada("A definir", 2, null, null);
        var c = parada("UNIFOR-MG", 3, -20.48, -45.44);
        comParadas(a, semCoord, c);
        when(planner.legDurationsSeconds(any()))
                .thenReturn(Optional.of(List.of(600.0)));

        useCase.recalculate(ROTA);

        verify(planner).legDurationsSeconds(List.of(
                new GeoPoint(-20.46, -45.42), new GeoPoint(-20.48, -45.44)));
        assertThat(semCoord.getAvgMinutesFromStart()).isNull();
        assertThat(c.getAvgMinutesFromStart()).isEqualTo(12);
    }

    @Test
    void rotaComUmaParadaNaoChamaOPlanejador() {
        comParadas(parada("Rodoviária", 1, -20.46, -45.42));

        useCase.recalculate(ROTA);

        verify(planner, never()).legDurationsSeconds(any());
    }

    @Test
    void rotaSemParadaNaoQuebra() {
        comParadas();

        useCase.recalculate(ROTA);

        verify(planner, never()).legDurationsSeconds(any());
    }

    @Test
    void respostaIncompletaDeixaOTempoNulo() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var b = parada("Centro", 2, -20.47, -45.43);
        var c = parada("UNIFOR-MG", 3, -20.48, -45.44);
        comParadas(a, b, c);
        when(planner.legDurationsSeconds(any()))
                .thenReturn(Optional.of(List.of(300.0)));

        useCase.recalculate(ROTA);

        assertThat(c.getAvgMinutesFromStart()).isNull();
    }

    @Test
    void rotaSemTempoNenhumEhCalculadaSobDemanda() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var b = parada("UNIFOR-MG", 2, -20.48, -45.44);
        comParadas(a, b);
        when(planner.legDurationsSeconds(any()))
                .thenReturn(Optional.of(List.of(600.0)));

        useCase.recalculateIfMissing(ROTA);

        assertThat(b.getAvgMinutesFromStart()).isEqualTo(12);
    }

    @Test
    void rotaJaCalculadaNaoChamaOPlanejadorDeNovo() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var b = parada("UNIFOR-MG", 2, -20.48, -45.44);
        a.setAvgMinutesFromStart(1);
        b.setAvgMinutesFromStart(13);
        comParadas(a, b);

        useCase.recalculateIfMissing(ROTA);

        verify(planner, never()).legDurationsSeconds(any());
        assertThat(b.getAvgMinutesFromStart()).isEqualTo(13);
    }
}
