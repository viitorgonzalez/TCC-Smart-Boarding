package com.smartboarding.smartboarding_api.domain.report.entity;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
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
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_list_id", nullable = false, unique = true)
    private DailyList dailyList;

    @Column(name = "generated_at", nullable = false)
    private LocalDateTime generatedAt;

    @Column(name = "total_entries", nullable = false)
    private int totalEntries;

    @Column(name = "snapshot_data", columnDefinition = "TEXT")
    private String snapshotData;

    /// JSON dos veículos propostos pelo algoritmo guloso da RN16.
    @Column(name = "proposed_vehicles", columnDefinition = "TEXT")
    private String proposedVehicles;

    /// Quantos inscritos ficaram sem lugar; 0 = frota cobre todo mundo.
    @Column(name = "capacity_shortfall", nullable = false)
    @Builder.Default
    private int capacityShortfall = 0;

    @PrePersist
    void onCreate() {
        generatedAt = LocalDateTime.now();
    }
}
