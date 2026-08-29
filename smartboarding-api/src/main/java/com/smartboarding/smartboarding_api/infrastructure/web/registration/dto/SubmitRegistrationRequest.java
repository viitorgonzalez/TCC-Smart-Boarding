package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

public record SubmitRegistrationRequest(
        @NotBlank(message = "fullName can't be empty") @Size(max = 150) String fullName,
        @NotBlank(message = "password can't be empty") @Size(min = 6) String password,
        @NotNull(message = "institutionId is required") UUID institutionId,
        @Size(max = 100) String course,
        @Size(max = 20) String phone,
        String address,
        LocalDate birthDate
) {}
