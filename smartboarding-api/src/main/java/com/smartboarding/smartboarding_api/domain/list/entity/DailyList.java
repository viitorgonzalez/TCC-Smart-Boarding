package com.smartboarding.smartboarding_api.domain.list.entity;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalTime;
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

    @Builder.Default
    @Column(name = "manual_override", nullable = false)
    private boolean manualOverride = false;

    @Column(name = "trip_started_at")
    private LocalDateTime tripStartedAt;

    @Column(name = "outbound_finished_at")
    private LocalDateTime outboundFinishedAt;

    @Column(name = "trip_finished_at")
    private LocalDateTime tripFinishedAt;

    /// Se a lista deveria estar aberta agora, pelo horario atual da rota.
    ///
    /// Mora aqui porque duas decisoes dependem dela e precisam concordar: o
    /// scheduler de minuto e a mudanca de horario feita pelo admin.
    public boolean isWithinSchedule(LocalDate today, LocalTime now) {
        if (!date.isEqual(today)) {
            return false;
        }
        return !now.isBefore(route.getOpenTime()) && now.isBefore(route.getCloseTime());
    }
}
