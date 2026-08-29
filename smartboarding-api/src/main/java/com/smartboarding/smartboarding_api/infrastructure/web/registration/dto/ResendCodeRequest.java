package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ResendCodeRequest(
        @NotBlank @Email(message = "e-mail inválido") @Size(max = 100) String email
) {}
