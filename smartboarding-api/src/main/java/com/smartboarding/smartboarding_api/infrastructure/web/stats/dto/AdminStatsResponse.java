package com.smartboarding.smartboarding_api.infrastructure.web.stats.dto;

import com.smartboarding.smartboarding_api.domain.stats.port.in.GetAdminStatsUseCase.AdminStats;

public record AdminStatsResponse(long activeStudents, long enrolledToday, long capacityToday,
                                  int occupancyPercent, long pendingProfileRequests, long warningsToday) {
    public static AdminStatsResponse from(AdminStats stats) {
        return new AdminStatsResponse(stats.activeStudents(), stats.enrolledToday(), stats.capacityToday(),
                stats.occupancyPercent(), stats.pendingProfileRequests(), stats.warningsToday());
    }
}
