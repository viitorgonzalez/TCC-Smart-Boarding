package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

/// Campo ausente = não foi pedida mudança nele. Por isso nada é @NotBlank: o
/// aluno manda só o que quer mudar.
public record ProfileUpdateRequestDto(
        @Size(max = 150) String fullName,
        @Size(max = 20) String phone,
        String address,
        @Size(max = 100) String course,
        UUID institutionId,
        LocalDate birthDate
) {}
