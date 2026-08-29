package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

// Carrega tudo que o aluno enviou: o admin precisa conferir os dados antes de
// aprovar ou negar, e o motivo da negação depende de ele ver o que está errado.
public record PendingRegistrationResponse(UUID id, String email, String fullName,
                                           UUID institutionId, String institutionName,
                                           String course, String phone, String address,
                                           LocalDate birthDate, LocalDateTime createdAt) {
    public static PendingRegistrationResponse from(RegistrationRequest request, String institutionName) {
        return new PendingRegistrationResponse(request.getId(), request.getEmail(), request.getFullName(),
                request.getInstitutionId(), institutionName,
                request.getCourse(), request.getPhone(), request.getAddress(),
                request.getBirthDate(), request.getCreatedAt());
    }
}
