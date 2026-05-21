package com.smartboarding.smartboarding_api.domain.report.entity;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Report {
    private UUID id;
    private DailyList dailyList;
    private LocalDateTime generatedAt;
    private int totalEntries;
    private String snapshotData;
}
