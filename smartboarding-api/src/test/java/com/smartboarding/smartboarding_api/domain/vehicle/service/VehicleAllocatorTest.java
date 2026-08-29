package com.smartboarding.smartboarding_api.domain.vehicle.service;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class VehicleAllocatorTest {

    private Vehicle vehicle(String label, int capacity) {
        return Vehicle.builder().label(label).capacity(capacity).build();
    }

    private final List<Vehicle> frota = List.of(vehicle("Ônibus", 45), vehicle("Van", 15));

    @Test
    void escolheOMenorQueJaCobreSozinho() {
        var result = VehicleAllocator.allocate(frota, 12);

        assertThat(result.vehicles()).extracting(Vehicle::getLabel).containsExactly("Van");
        assertThat(result.isSufficient()).isTrue();
    }

    @Test
    void usaOOnibusQuandoAVanNaoCobre() {
        var result = VehicleAllocator.allocate(frota, 30);

        assertThat(result.vehicles()).extracting(Vehicle::getLabel).containsExactly("Ônibus");
        assertThat(result.isSufficient()).isTrue();
    }

    @Test
    void somaOsDoisQuandoUmSoNaoBasta() {
        var result = VehicleAllocator.allocate(frota, 50);

        assertThat(result.vehicles()).extracting(Vehicle::getLabel)
                .containsExactlyInAnyOrder("Ônibus", "Van");
        assertThat(result.isSufficient()).isTrue();
    }

    @Test
    void marcaFaltaDeLugarQuandoAFrotaNaoCobre() {
        var result = VehicleAllocator.allocate(frota, 70);

        assertThat(result.vehicles()).hasSize(2);
        assertThat(result.shortfall()).isEqualTo(10);
        assertThat(result.isSufficient()).isFalse();
    }

    @Test
    void listaVaziaNaoPropoeNada() {
        var result = VehicleAllocator.allocate(frota, 0);

        assertThat(result.vehicles()).isEmpty();
        assertThat(result.isSufficient()).isTrue();
    }

    @Test
    void semFrotaCadastradaTodosFicamSemLugar() {
        var result = VehicleAllocator.allocate(List.of(), 8);

        assertThat(result.vehicles()).isEmpty();
        assertThat(result.shortfall()).isEqualTo(8);
    }
}
