package com.smartboarding.smartboarding_api.domain.stats.port.in;

public interface GetAdminStatsUseCase {

    record AdminStats(long activeStudents, long enrolledToday, long capacityToday,
                       int occupancyPercent, long pendingProfileRequests, long warningsToday) {}

    AdminStats execute();
}
