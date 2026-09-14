package com.smartboarding.smartboarding_api.domain.user.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_status_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserStatusLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /// Nulo só se o admin for removido depois — o registro sobrevive a ele.
    @Column(name = "admin_id")
    private UUID adminId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserStatusAction action;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
