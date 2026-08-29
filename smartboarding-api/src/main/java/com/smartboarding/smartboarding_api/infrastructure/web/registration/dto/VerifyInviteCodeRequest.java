package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;

public record VerifyInviteCodeRequest(
        @NotBlank @Email(message = "e-mail inválido") @Size(max = 100) String email,
        @NotBlank @Pattern(regexp = "\\d{6}", message = "código deve ter 6 dígitos") String code
) {}
