package com.smartboarding.smartboarding_api.domain.trip.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/// Chegada do ônibus num ponto principal. Guardado pra a tela saber por onde já
/// passou e pra o dia deixar histórico.
@Entity
@Table(name = "trip_checkpoints",
       uniqueConstraints = @UniqueConstraint(columnNames = {"daily_list_id", "stop_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TripCheckpoint {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "daily_list_id", nullable = false)
    private UUID dailyListId;

    @Column(name = "stop_id", nullable = false)
    private UUID stopId;

    @Column(name = "reached_at", nullable = false)
    private LocalDateTime reachedAt;
}
