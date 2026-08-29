package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;

import java.time.LocalDate;
import java.util.UUID;

// Carrega os dados já submetidos pra o aluno negado voltar e corrigir em vez de
// redigitar tudo (RN14). O hash da senha nunca sai daqui — a senha é sempre
// redigitada no reenvio.
public record InviteInfoResponse(String email, RegistrationStatus status, String rejectionReason,
                                 String fullName, UUID institutionId, String course,
                                 String phone, String address, LocalDate birthDate) {
    public static InviteInfoResponse from(RegistrationRequest request) {
        return new InviteInfoResponse(
                request.getEmail(),
                request.getStatus(),
                request.getRejectionReason(),
                request.getFullName(),
                request.getInstitutionId(),
                request.getCourse(),
                request.getPhone(),
                request.getAddress(),
                request.getBirthDate());
    }
}
