package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;

import java.time.LocalDate;
import java.util.UUID;

public record ListResponse(UUID id, UUID routeId, String routeName, LocalDate date, ListStatus status, long totalEntries) {
    public static ListResponse from(DailyList list, long totalEntries) {
        return new ListResponse(
                list.getId(),
                list.getRoute().getId(),
                list.getRoute().getName(),
                list.getDate(),
                list.getStatus(),
                totalEntries
        );
    }
}
