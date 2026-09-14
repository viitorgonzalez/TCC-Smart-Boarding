package com.smartboarding.smartboarding_api.domain.membership.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/// Código que dá acesso a uma rota. Um por rota, distribuído pra turma toda, com
/// prazo — igual código de turma do Classroom.
@Entity
@Table(name = "route_invite_codes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RouteInviteCode {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "route_id", nullable = false)
    private UUID routeId;

    @Column(nullable = false, length = 16, unique = true)
    private String code;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /// Preenchido revoga na hora, sem esperar a expiração.
    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /// Revogado e expirado são estados distintos pro admin, mas valem o mesmo na
    /// hora de usar: o código não serve mais.
    public boolean isUsable(LocalDateTime now) {
        return revokedAt == null && now.isBefore(expiresAt);
    }

    public boolean isExpired(LocalDateTime now) {
        return !now.isBefore(expiresAt);
    }

    public boolean isRevoked() {
        return revokedAt != null;
    }

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
