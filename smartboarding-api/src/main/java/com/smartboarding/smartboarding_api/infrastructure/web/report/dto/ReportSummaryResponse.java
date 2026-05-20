package com.smartboarding.smartboarding_api.infrastructure.web.report.dto;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record ReportSummaryResponse(UUID id, UUID dailyListId, LocalDate listDate, String routeName,
                                    int totalEntries, LocalDateTime generatedAt) {
    public static ReportSummaryResponse from(Report report) {
        return new ReportSummaryResponse(
                report.getId(),
                report.getDailyList().getId(),
                report.getDailyList().getDate(),
                report.getDailyList().getRoute().getName(),
                report.getTotalEntries(),
                report.getGeneratedAt()
        );
    }
}
