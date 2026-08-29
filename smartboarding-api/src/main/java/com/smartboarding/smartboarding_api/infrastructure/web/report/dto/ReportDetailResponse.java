package com.smartboarding.smartboarding_api.infrastructure.web.report.dto;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record ReportDetailResponse(UUID id, UUID dailyListId, LocalDate listDate, String routeName,
                                   int totalEntries, LocalDateTime generatedAt, String snapshotData,
                                   String proposedVehicles, int capacityShortfall) {
    public static ReportDetailResponse from(Report report) {
        return new ReportDetailResponse(
                report.getId(),
                report.getDailyList().getId(),
                report.getDailyList().getDate(),
                report.getDailyList().getRoute().getName(),
                report.getTotalEntries(),
                report.getGeneratedAt(),
                report.getSnapshotData(),
                report.getProposedVehicles(),
                report.getCapacityShortfall()
        );
    }
}
