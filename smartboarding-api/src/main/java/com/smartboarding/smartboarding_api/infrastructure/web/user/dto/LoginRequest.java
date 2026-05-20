package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "email can't be null or empty") @Email String email,
        @NotBlank(message = "password can't be null or empty") String password
) {}
