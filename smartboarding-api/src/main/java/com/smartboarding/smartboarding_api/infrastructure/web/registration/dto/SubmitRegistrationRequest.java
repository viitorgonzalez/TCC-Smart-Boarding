package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

public record SubmitRegistrationRequest(
        @NotBlank(message = "fullName can't be empty") String fullName,
        @NotBlank(message = "password can't be empty") String password,
        @NotNull(message = "institutionId is required") UUID institutionId,
        String course,
        String phone,
        String address,
        LocalDate birthDate
) {}
