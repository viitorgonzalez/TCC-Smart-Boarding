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
        List<InstitutionCount> entriesByInstitution,
        List<VehicleSummary> vehicles,
        List<VehicleSummary> proposedVehicles,
        int capacityShortfall,
        List<StopPoint> stops,
        boolean tripInProgress,
        MyTripTime myTripTime) {

    public record InstitutionCount(String name, long count) {}

    public record VehicleSummary(String label, int capacity) {}

    public record StopPoint(String name, Double latitude, Double longitude, int sequence) {}

    public record MyTripTime(String stopName, int avgMinutes, boolean fallback) {}

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
                list.getTripStartedAt() != null && list.getTripFinishedAt() == null,
                myTripTime
        );
    }
}
