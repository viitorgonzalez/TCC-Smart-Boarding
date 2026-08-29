package com.smartboarding.smartboarding_api.application.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class StopUseCaseImplTest {

    private static final UUID ROUTE = UUID.randomUUID();

    @Mock StopRepositoryPort repository;

    private Stop stop(String name, int seq) {
        return Stop.builder().id(UUID.randomUUID()).routeId(ROUTE).name(name).sequence(seq).build();
    }

    private List<Stop> route(Stop... stops) {
        var list = new ArrayList<>(List.of(stops));
        when(repository.findAllByRouteIdOrderBySequenceAsc(ROUTE)).thenReturn(list);
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        return list;
    }

    @Test
    void semSequenciaEntraNoFim() {
        route(stop("A", 1), stop("B", 2));
        var nova = Stop.builder().routeId(ROUTE).name("C").build();

        var saved = new StopUseCaseImpl(repository).add(nova);

        assertThat(saved.getSequence()).isEqualTo(3);
    }

    @Test
    void inserirNoMeioEmpurraAsSeguintes() {
        var a = stop("A", 1);
        var b = stop("B", 2);
        var c = stop("C", 3);
        route(a, b, c);
        var nova = Stop.builder().routeId(ROUTE).name("Nova").sequence(2).build();

        new StopUseCaseImpl(repository).add(nova);

        assertThat(a.getSequence()).isEqualTo(1);
        assertThat(b.getSequence()).isEqualTo(3);
        assertThat(c.getSequence()).isEqualTo(4);
    }

    @Test
    void moverAtualizaSoAsCoordenadas() {
        var a = stop("A", 1);
        when(repository.findById(a.getId())).thenReturn(Optional.of(a));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var moved = new StopUseCaseImpl(repository).update(a.getId(), null, -20.5, -45.5);

        assertThat(moved.getName()).isEqualTo("A");
        assertThat(moved.getLatitude()).isEqualTo(-20.5);
    }

    @Test
    void removerRenumeraParaNaoDeixarBuraco() {
        var a = stop("A", 1);
        var c = stop("C", 3);
        when(repository.findById(a.getId())).thenReturn(Optional.of(a));
        when(repository.findAllByRouteIdOrderBySequenceAsc(ROUTE)).thenReturn(new ArrayList<>(List.of(c)));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        new StopUseCaseImpl(repository).remove(a.getId());

        assertThat(c.getSequence()).isEqualTo(1);
    }
}
