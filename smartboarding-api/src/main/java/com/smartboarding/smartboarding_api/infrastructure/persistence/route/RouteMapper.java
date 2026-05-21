package com.smartboarding.smartboarding_api.infrastructure.persistence.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

public class RouteMapper {

    public static Route toDomain(RouteJpaEntity e) {
        if (e == null) return null;
        return Route.builder()
                .id(e.getId())
                .name(e.getName())
                .description(e.getDescription())
                .isActive(e.isActive())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }

    public static RouteJpaEntity toJpa(Route r) {
        if (r == null) return null;
        return RouteJpaEntity.builder()
                .id(r.getId())
                .name(r.getName())
                .description(r.getDescription())
                .isActive(r.isActive())
                .createdAt(r.getCreatedAt())
                .updatedAt(r.getUpdatedAt())
                .build();
    }
}
