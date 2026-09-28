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
        List<StopPoint> stops,
        /// Trajeto em andamento. O card do aluno usa pra decidir se oferece
        /// "Acompanhar trajeto" -- oferecer sempre levaria a uma tela que só
        /// diz "não começou", e esconder sempre esconderia a feature.
        boolean tripInProgress,
        /// Quanto a viagem leva até a instituição DESTE aluno. Nulo pro admin
        /// (ele não viaja) e quando não dá pra saber.
        MyTripTime myTripTime) {

    public record InstitutionCount(String name, long count) {}

    public record VehicleSummary(String label, int capacity) {}

    public record StopPoint(String name, Double latitude, Double longitude, int sequence) {}

    /// O tempo médio até a parada do aluno, com o nome do destino.
    ///
    /// O nome vem junto porque dois alunos da mesma rota veem números
    /// diferentes: sem dizer até onde, quem compara com o colega conclui que o
    /// app está errado.
    public record MyTripTime(String stopName, int avgMinutes, boolean fallback) {}

    /**
     * @param myEntry inscrição do usuário logado nesta lista (pode ser null ou inativa).
     */
    public static ListResponse from(DailyList list, long totalEntries, ListEntry myEntry,
                                    List<InstitutionCount> entriesByInstitution,
                                    List<VehicleSummary> vehicles,
                                    List<VehicleSummary> proposedVehicles,
                                    int capacityShortfall,
                                    List<StopPoint> stops,
                                    MyTripTime myTripTime) {
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
                stops,
                // Em andamento = começou e não acabou. É o único estado em que
                // acompanhar tem o que mostrar.
                list.getTripStartedAt() != null && list.getTripFinishedAt() == null,
                myTripTime
        );
    }
}
