package com.smartboarding.smartboarding_api.domain.notification.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    /// Rota destinatária. A coluna aceita nulo só por causa de avisos gerais
    /// antigos — nada no sistema publica sem rota desde então.
    @Column(name = "route_id")
    private UUID routeId;

    @Column(name = "created_by")
    private UUID createdBy;

    /// Nulo = sem prazo de validade.
    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public boolean isExpired(LocalDateTime now) {
        return expiresAt != null && now.isAfter(expiresAt);
    }
}
