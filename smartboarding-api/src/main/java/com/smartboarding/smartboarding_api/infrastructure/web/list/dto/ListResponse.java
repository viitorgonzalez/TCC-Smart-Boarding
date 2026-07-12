package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.time.LocalDate;
import java.util.UUID;

public record ListResponse(
        UUID id,
        UUID routeId,
        String routeName,
        LocalDate date,
        ListStatus status,
        long totalEntries,
        boolean enrolled,
        TripType tripType) {

    /**
     * @param myEntry inscrição do usuário logado nesta lista (pode ser null ou inativa).
     */
    public static ListResponse from(DailyList list, long totalEntries, ListEntry myEntry) {
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
                tripType
        );
    }
}
