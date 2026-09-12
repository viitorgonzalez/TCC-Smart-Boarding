package com.smartboarding.smartboarding_api.domain.membership.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/// Vínculo aluno↔rota. Substitui a derivação por instituição: o aluno pode estar
/// em mais de uma rota, e entrar em cada uma exige o código daquela rota.
@Entity
@Table(name = "route_members")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RouteMember {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "route_id", nullable = false)
    private UUID routeId;

    /// Nulo = vínculo que não veio de código: a migração dos alunos antigos, ou
    /// o admin adicionando à mão. É o que permite contar quantos entraram por
    /// cada código.
    @Column(name = "invite_code_id")
    private UUID inviteCodeId;

    @Column(name = "joined_at", updatable = false)
    private LocalDateTime joinedAt;

    @PrePersist
    void onCreate() {
        if (joinedAt == null) {
            joinedAt = LocalDateTime.now();
        }
    }
}
