package com.smartboarding.smartboarding_api.domain.stop.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "stops")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Stop {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "route_id", nullable = false)
    private UUID routeId;

    @Column(nullable = false, length = 150)
    private String name;

    private Double latitude;
    private Double longitude;

    @Column(name = "sequence", nullable = false)
    private int sequence;

    @Column(name = "institution_id")
    private UUID institutionId;

    @Builder.Default
    @Column(name = "is_main_point", nullable = false)
    private boolean isMainPoint = false;

    public void refreshMainPoint(boolean marcadoPeloAdmin) {
        this.isMainPoint = institutionId != null || marcadoPeloAdmin;
    }

    @Column(name = "avg_minutes_from_start")
    private Integer avgMinutesFromStart;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
