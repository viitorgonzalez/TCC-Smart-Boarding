package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
        @NotBlank(message = "informe sua senha atual") String currentPassword,

        @NotBlank(message = "informe a nova senha")
        @Size(min = 6, max = 100) String newPassword
) {}
