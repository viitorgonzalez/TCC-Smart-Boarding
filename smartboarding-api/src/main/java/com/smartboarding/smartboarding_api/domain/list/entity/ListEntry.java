package com.smartboarding.smartboarding_api.domain.list.entity;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "list_entries", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "daily_list_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ListEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_list_id", nullable = false)
    private DailyList dailyList;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "trip_type", nullable = false, length = 20)
    @Builder.Default
    private TripType tripType = TripType.ROUND_TRIP;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
