package com.smartboarding.smartboarding_api.domain.route.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "routes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Route {

    public static final LocalTime DEFAULT_OPEN_TIME = LocalTime.of(0, 0);
    public static final LocalTime DEFAULT_CLOSE_TIME = LocalTime.of(16, 0);

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 255)
    private String description;

    // Sem @Builder.Default o Lombok ignora o inicializador e toda rota criada via
    // builder (POST /api/routes) nascia inativa — e rota inativa nunca ganha lista.
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean isActive = true;

    // Horário em que a lista do dia dessa rota passa a aceitar inscrição.
    @Column(name = "open_time", nullable = false)
    @Builder.Default
    private LocalTime openTime = DEFAULT_OPEN_TIME;

    // Horário em que ela para de aceitar (RN18).
    @Column(name = "close_time", nullable = false)
    @Builder.Default
    private LocalTime closeTime = DEFAULT_CLOSE_TIME;

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
