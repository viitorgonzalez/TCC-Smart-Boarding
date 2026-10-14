package com.smartboarding.smartboarding_api.domain.profile.entity;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

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

    @Embedded
    private Address structuredAddress;

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

    public boolean isEmpty() {
        return fullName == null && institutionId == null && birthDate == null
                && phone == null && course == null && structuredAddress == null;
    }

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
