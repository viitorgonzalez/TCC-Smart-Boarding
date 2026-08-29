package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

public record RouteResponse(UUID id, String name, String description, boolean isActive,
                            LocalTime openTime, LocalTime closeTime,
                            LocalDateTime createdAt) {
    public static RouteResponse from(Route route) {
        return new RouteResponse(route.getId(), route.getName(), route.getDescription(),
                route.isActive(), route.getOpenTime(), route.getCloseTime(), route.getCreatedAt());
    }
}
