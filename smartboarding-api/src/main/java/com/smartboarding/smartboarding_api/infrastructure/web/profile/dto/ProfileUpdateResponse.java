package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record ProfileUpdateResponse(UUID id, UUID userId, String studentName,
                                    String fullName, String phone, String address,
                                    String course, UUID institutionId, LocalDate birthDate,
                                    String status, String rejectionReason,
                                    LocalDateTime createdAt) {

    public static ProfileUpdateResponse from(ProfileUpdateRequest r, String studentName) {
        return new ProfileUpdateResponse(
                r.getId(), r.getUserId(), studentName,
                r.getFullName(), r.getPhone(), r.getAddress(),
                r.getCourse(), r.getInstitutionId(), r.getBirthDate(),
                r.getStatus().name(), r.getRejectionReason(), r.getCreatedAt());
    }
}
