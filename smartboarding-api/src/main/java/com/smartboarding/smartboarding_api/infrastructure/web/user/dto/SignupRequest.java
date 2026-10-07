package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SignupRequest(
        @NotBlank(message = "informe seu nome") @Size(max = 150) String fullName,
        @NotBlank(message = "informe seu e-mail") @Email(message = "e-mail inválido")
        @Size(max = 100) String email,
        @NotBlank(message = "informe uma senha") @Size(min = 6, max = 100) String password
) {}
