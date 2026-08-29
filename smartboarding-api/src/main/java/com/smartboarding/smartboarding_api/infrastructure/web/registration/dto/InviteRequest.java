package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record InviteRequest(
        @NotBlank @Email(message = "e-mail inválido") String email
) {}
