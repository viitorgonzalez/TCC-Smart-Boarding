package com.smartboarding.smartboarding_api.infrastructure.persistence.report;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import com.smartboarding.smartboarding_api.infrastructure.persistence.list.DailyListMapper;

public class ReportMapper {

    public static Report toDomain(ReportJpaEntity e) {
        if (e == null) return null;
        return Report.builder()
                .id(e.getId())
                .dailyList(DailyListMapper.toDomain(e.getDailyList()))
                .generatedAt(e.getGeneratedAt())
                .totalEntries(e.getTotalEntries())
                .snapshotData(e.getSnapshotData())
                .build();
    }

    public static ReportJpaEntity toJpa(Report r) {
        if (r == null) return null;
        return ReportJpaEntity.builder()
                .id(r.getId())
                .dailyListId(r.getDailyList() != null ? r.getDailyList().getId() : null)
                .generatedAt(r.getGeneratedAt())
                .totalEntries(r.getTotalEntries())
                .snapshotData(r.getSnapshotData())
                .build();
    }
}
