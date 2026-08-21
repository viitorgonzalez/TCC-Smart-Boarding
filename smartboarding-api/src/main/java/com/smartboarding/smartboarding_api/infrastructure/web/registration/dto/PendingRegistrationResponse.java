package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.time.LocalDateTime;
import java.util.UUID;

public record PendingRegistrationResponse(UUID id, String email, String fullName,
                                           UUID institutionId, String institutionName, LocalDateTime createdAt) {
    public static PendingRegistrationResponse from(RegistrationRequest request, String institutionName) {
        return new PendingRegistrationResponse(request.getId(), request.getEmail(), request.getFullName(),
                request.getInstitutionId(), institutionName, request.getCreatedAt());
    }
}
