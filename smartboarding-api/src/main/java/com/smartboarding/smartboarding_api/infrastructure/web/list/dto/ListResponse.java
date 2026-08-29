package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

public record ListResponse(
        UUID id,
        UUID routeId,
        String routeName,
        LocalDate date,
        ListStatus status,
        long totalEntries,
        boolean enrolled,
        TripType tripType,
        LocalTime closeTime,
        // Uma rota atende várias instituições (RN15); o admin usa a divisão pra
        // dimensionar o transporte.
        List<InstitutionCount> entriesByInstitution,
        // Capacidade é informação do transporte, não teto de inscrição.
        List<VehicleSummary> vehicles,
        // Preenchido só após o fechamento, lido do relatório (RN16).
        List<VehicleSummary> proposedVehicles,
        int capacityShortfall,
        // Junto da lista pra o card desenhar o trajeto sem uma segunda chamada.
        List<StopPoint> stops) {

    public record InstitutionCount(String name, long count) {}

    public record VehicleSummary(String label, int capacity) {}

    public record StopPoint(String name, Double latitude, Double longitude, int sequence) {}

    /**
     * @param myEntry inscrição do usuário logado nesta lista (pode ser null ou inativa).
     */
    public static ListResponse from(DailyList list, long totalEntries, ListEntry myEntry,
                                    List<InstitutionCount> entriesByInstitution,
                                    List<VehicleSummary> vehicles,
                                    List<VehicleSummary> proposedVehicles,
                                    int capacityShortfall,
                                    List<StopPoint> stops) {
        boolean enrolled = myEntry != null && myEntry.isActive();
        TripType tripType = enrolled ? myEntry.getTripType() : null;
        return new ListResponse(
                list.getId(),
                list.getRoute().getId(),
                list.getRoute().getName(),
                list.getDate(),
                list.getStatus(),
                totalEntries,
                enrolled,
                tripType,
                list.getRoute().getCloseTime(),
                entriesByInstitution,
                vehicles,
                proposedVehicles,
                capacityShortfall,
                stops
        );
    }
}
