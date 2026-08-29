package com.smartboarding.smartboarding_api.domain.notification.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "scheduled_notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ScheduledNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "route_id", nullable = false)
    private UUID routeId;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NotificationFrequency frequency;

    @Column(name = "send_at", nullable = false)
    private LocalTime sendAt;

    /// Só para WEEKLY.
    @Column(name = "day_of_week")
    private Integer dayOfWeek;

    @Column(name = "duration_hours")
    private Integer durationHours;

    @Column(nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "last_sent_at")
    private LocalDateTime lastSentAt;

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

    /// Chegou a hora e ainda não saiu hoje. A checagem por dia é o que impede a
    /// varredura de repetir o aviso a cada cinco minutos.
    public boolean isDue(LocalDateTime now) {
        if (!active || !matchesDay(now.getDayOfWeek())) {
            return false;
        }
        if (now.toLocalTime().isBefore(sendAt)) {
            return false;
        }
        return lastSentAt == null || lastSentAt.toLocalDate().isBefore(now.toLocalDate());
    }

    private boolean matchesDay(DayOfWeek today) {
        return switch (frequency) {
            case DAILY -> true;
            case WEEKDAYS -> today != DayOfWeek.SATURDAY && today != DayOfWeek.SUNDAY;
            case WEEKLY -> dayOfWeek != null && dayOfWeek == today.getValue();
        };
    }
}
