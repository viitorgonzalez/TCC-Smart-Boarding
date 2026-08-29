package com.smartboarding.smartboarding_api.domain.warning.entity;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/// Registro de que o aluno entrou na lista fora do horário e precisou do admin.
/// Colocar o nome no prazo é responsabilidade dele — a advertência é a memória
/// disso, não uma punição automática: quem decide emitir é o admin.
@Entity
@Table(name = "warnings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Warning {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_list_id")
    private DailyList dailyList;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String reason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issued_by")
    private User issuedBy;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
