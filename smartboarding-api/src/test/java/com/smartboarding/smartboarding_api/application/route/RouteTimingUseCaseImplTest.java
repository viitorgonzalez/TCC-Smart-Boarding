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

    /// 1 min por parada é o tempo de embarque. Sem ele o número fica otimista
    /// e o aluno perde o ônibus achando que dava tempo.
    @Test
    void somaUmMinutoDeEmbarquePorParada() {
        var a = parada("Rodoviária", 1, -20.46, -45.42);
        var b = parada("Centro", 2, -20.47, -45.43);
        var c = parada("UNIFOR-MG", 3, -20.48, -45.44);
        comParadas(a, b, c);
        // 600s (10 min) do início até a terceira, quebrados em dois trechos.
        when(planner.legDurationsSeconds(any()))
                .thenReturn(Optional.of(List.of(300.0, 300.0)));

        useCase.recalculate(ROTA);

        assertThat(a.getAvgMinutesFromStart()).isEqualTo(1);
        assertThat(b.getAvgMinutesFromStart()).isEqualTo(7);
        assertThat(c.getAvgMinutesFromStart()).isEqualTo(13);
    }

    /// Nulo é "não sei", e a tela omite. Um zero ali viraria "o ônibus já
    /// chegou" — pior que não mostrar nada.
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

    /// Parada sem coordenada não entra na conta: mandá-la ao OSRM como (0,0)
    /// desenharia um trajeto passando pelo Golfo da Guiné.
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

    /// Uma parada só não tem trecho pra medir, e chamar o OSRM com um ponto
    /// gastaria requisição pra receber erro.
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

    /// Menos durações do que trechos significa resposta truncada. Completar com
    /// zero daria um tempo que parece certo e não é.
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
}
