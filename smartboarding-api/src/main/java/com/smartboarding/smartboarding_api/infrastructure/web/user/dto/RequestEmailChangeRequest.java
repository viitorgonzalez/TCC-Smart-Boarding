package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RequestEmailChangeRequest(
        @NotBlank(message = "informe o novo e-mail") @Email(message = "e-mail inválido")
        @Size(max = 100) String newEmail
) {}
