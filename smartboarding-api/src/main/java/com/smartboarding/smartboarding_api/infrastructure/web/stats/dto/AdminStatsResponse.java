package com.smartboarding.smartboarding_api.infrastructure.web.stats.dto;

import com.smartboarding.smartboarding_api.domain.stats.port.in.GetAdminStatsUseCase.AdminStats;

public record AdminStatsResponse(long activeStudents, long routesInUse, int occupancyPercent) {
    public static AdminStatsResponse from(AdminStats stats) {
        return new AdminStatsResponse(stats.activeStudents(), stats.routesInUse(), stats.occupancyPercent());
    }
}
