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

    /// A instituição que esta parada serve, quando serve alguma.
    ///
    /// Explícito, e não adivinhado pelo nome: até a V32 o vínculo saía de
    /// `s.name LIKE i.name || '%'`, então renomear a parada pra "Portão 2 da
    /// UNIFOR" o desfazia em silêncio -- e ninguém percebia até o aluno ver o
    /// tempo da parada errada.
    @Column(name = "institution_id")
    private UUID institutionId;

    /// RN23: só ponto principal (rodoviária e instituições) aceita checkpoint.
    ///
    /// Continua sendo campo e não puro derivado porque a rodoviária é ponto
    /// principal sem ser instituição nenhuma. Quem serve instituição vira
    /// principal sozinho (ver [refreshMainPoint]).
    @Builder.Default
    @Column(name = "is_main_point", nullable = false)
    private boolean isMainPoint = false;

    /// Parada que serve instituição é sempre ponto principal; o resto depende
    /// do que o admin marcou.
    ///
    /// Chamado a cada escrita porque até a V32 **nada** em produção escrevia
    /// esse campo -- só a migration V20, uma vez. Toda rota criada depois dela
    /// nascia sem nenhum ponto principal, e o trajeto recusava todo checkpoint.
    public void refreshMainPoint(boolean marcadoPeloAdmin) {
        this.isMainPoint = institutionId != null || marcadoPeloAdmin;
    }

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
