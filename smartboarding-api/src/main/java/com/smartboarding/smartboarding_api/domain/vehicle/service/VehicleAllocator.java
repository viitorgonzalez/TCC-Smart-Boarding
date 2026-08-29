package com.smartboarding.smartboarding_api.domain.vehicle.service;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/// Algoritmo guloso da RN16: aloca o maior veículo primeiro e, pro resto,
/// escolhe o MENOR que ainda cubra — evita mandar um ônibus vazio pra levar
/// três pessoas. Heurística, não a combinação ótima: suficiente pro porte da
/// frota de uma rota.
public final class VehicleAllocator {

    private VehicleAllocator() {}

    public record Allocation(List<Vehicle> vehicles, int shortfall) {
        public boolean isSufficient() {
            return shortfall == 0;
        }
    }

    public static Allocation allocate(List<Vehicle> fleet, int passengers) {
        List<Vehicle> available = new ArrayList<>(fleet);
        available.sort(Comparator.comparingInt(Vehicle::getCapacity).reversed());

        List<Vehicle> chosen = new ArrayList<>();
        int remaining = passengers;

        while (remaining > 0 && !available.isEmpty()) {
            Vehicle pick = smallestThatCovers(available, remaining);
            if (pick == null) {
                // Ninguém cobre o resto sozinho: leva o maior e segue com o que sobrar.
                pick = available.getFirst();
            }
            chosen.add(pick);
            available.remove(pick);
            remaining -= pick.getCapacity();
        }

        return new Allocation(chosen, Math.max(remaining, 0));
    }

    private static Vehicle smallestThatCovers(List<Vehicle> available, int remaining) {
        return available.stream()
                .filter(v -> v.getCapacity() >= remaining)
                .min(Comparator.comparingInt(Vehicle::getCapacity))
                .orElse(null);
    }
}
