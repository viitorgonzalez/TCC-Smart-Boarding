package com.smartboarding.smartboarding_api.DTO.auth;

import com.smartboarding.smartboarding_api.Enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterRequestDTO(
        @NotBlank(message = "email can't be empty") @Email String email,
        @NotBlank(message = "password can't be empty") @Size(min = 6) String password,
        @NotNull(message = "role can't be null or empty") Role role,
        @NotBlank(message = "full name can't be empty") String fullName
) {}
