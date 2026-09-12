package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SetPasswordRequest(
        /// RN10: mínimo de 6 caracteres.
        @NotBlank(message = "informe uma senha") @Size(min = 6, max = 100) String password
) {}
