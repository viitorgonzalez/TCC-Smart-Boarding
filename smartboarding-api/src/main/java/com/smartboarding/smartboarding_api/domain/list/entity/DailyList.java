package com.smartboarding.smartboarding_api.domain.list.entity;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "daily_lists", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"route_id", "date"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyList {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id", nullable = false)
    private Route route;

    @Column(nullable = false)
    private LocalDate date;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private ListStatus status;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    /// O admin mexeu no status na mão hoje. A varredura respeita a decisão dele
    /// até o dia virar — sem isso, reabrir depois do horário durava 5 minutos.
    @Builder.Default
    @Column(name = "manual_override", nullable = false)
    private boolean manualOverride = false;

    @Column(name = "trip_started_at")
    private LocalDateTime tripStartedAt;

    @Column(name = "trip_finished_at")
    private LocalDateTime tripFinishedAt;
}
