package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank @Email @Size(max = 100) String email,
        @NotBlank @Pattern(regexp = "\\d{6}", message = "O código tem 6 dígitos") String code,
        @NotBlank @Size(min = 6, max = 100) String newPassword
) {}
