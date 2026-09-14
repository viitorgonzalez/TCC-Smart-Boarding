package com.smartboarding.smartboarding_api.application.vehicle;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VehicleUseCaseImplTest {

    private static final UUID ROUTE = UUID.randomUUID();

    @Mock VehicleRepositoryPort repository;

    @Test
    void listarFiltraPelaRota() {
        var frota = List.of(Vehicle.builder().routeId(ROUTE).label("Ônibus 01").capacity(44).build());
        when(repository.findAllByRouteId(ROUTE)).thenReturn(frota);

        assertThat(new VehicleUseCaseImpl(repository).listByRoute(ROUTE)).isEqualTo(frota);
    }

    @Test
    void adicionarDevolveOVeiculoPersistido() {
        var novo = Vehicle.builder().routeId(ROUTE).label("Van 02").capacity(15).build();
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var saved = new VehicleUseCaseImpl(repository).add(novo);

        assertThat(saved.getLabel()).isEqualTo("Van 02");
        assertThat(saved.getCapacity()).isEqualTo(15);
    }

    @Test
    void removerDelegaPeloId() {
        UUID id = UUID.randomUUID();

        new VehicleUseCaseImpl(repository).remove(id);

        verify(repository).deleteById(id);
    }
}
