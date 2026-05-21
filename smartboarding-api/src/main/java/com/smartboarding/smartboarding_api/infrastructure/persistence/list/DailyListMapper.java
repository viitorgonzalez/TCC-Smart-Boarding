package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.infrastructure.persistence.route.RouteMapper;

public class DailyListMapper {

    public static DailyList toDomain(DailyListJpaEntity e) {
        if (e == null) return null;
        return DailyList.builder()
                .id(e.getId())
                .route(RouteMapper.toDomain(e.getRoute()))
                .date(e.getDate())
                .status(e.getStatus())
                .closedAt(e.getClosedAt())
                .build();
    }

    public static DailyListJpaEntity toJpa(DailyList d) {
        if (d == null) return null;
        return DailyListJpaEntity.builder()
                .id(d.getId())
                .routeId(d.getRoute() != null ? d.getRoute().getId() : null)
                .date(d.getDate())
                .status(d.getStatus())
                .closedAt(d.getClosedAt())
                .build();
    }
}
