package com.smartboarding.smartboarding_api.domain.profile.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/// Pedido de atualização de perfil, no mesmo padrão do fluxo de aprovação que o
/// cadastro por convite tinha (RN14).
///
/// Guarda os valores PEDIDOS, não um diff: entre o pedido e a aprovação o valor
/// atual pode mudar, e aplicar um diff velho sobrescreveria o que mudou no meio.
@Entity
@Table(name = "profile_update_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfileUpdateRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /// Campo nulo = não foi pedida mudança nele. Distinguir "não pedi" de
    /// "pedi vazio" é o que evita apagar dado que o aluno não quis mexer.
    @Column(name = "full_name", length = 150)
    private String fullName;

    @Column(length = 20)
    private String phone;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(length = 100)
    private String course;

    @Column(name = "institution_id")
    private UUID institutionId;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private ProfileUpdateStatus status = ProfileUpdateStatus.PENDING;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "reviewed_by")
    private UUID reviewedBy;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public boolean isPending() {
        return status == ProfileUpdateStatus.PENDING;
    }

    /// Pedido sem nenhum campo preenchido não muda nada e só ocuparia a fila.
    public boolean isEmpty() {
        return fullName == null && phone == null && address == null
                && course == null && institutionId == null && birthDate == null;
    }

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
