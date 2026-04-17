package com.smartboarding.smartboarding_api.DTO.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequestDTO(
        @NotBlank(message = "email can't be null or empty") @Email String email,
        @NotBlank(message = "password can't be null or empty") String password
) {}
