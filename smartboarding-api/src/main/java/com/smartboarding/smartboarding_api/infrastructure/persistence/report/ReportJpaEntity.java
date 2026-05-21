package com.smartboarding.smartboarding_api.infrastructure.persistence.report;

import com.smartboarding.smartboarding_api.infrastructure.persistence.list.DailyListJpaEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "reports")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReportJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "daily_list_id", nullable = false, unique = true)
    private UUID dailyListId;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "daily_list_id", insertable = false, updatable = false)
    private DailyListJpaEntity dailyList;

    @Column(name = "generated_at", nullable = false)
    private LocalDateTime generatedAt;

    @Column(name = "total_entries", nullable = false)
    private int totalEntries;

    @Column(name = "snapshot_data", columnDefinition = "TEXT")
    private String snapshotData;

    @PrePersist
    void onCreate() {
        if (generatedAt == null) generatedAt = LocalDateTime.now();
    }
}
