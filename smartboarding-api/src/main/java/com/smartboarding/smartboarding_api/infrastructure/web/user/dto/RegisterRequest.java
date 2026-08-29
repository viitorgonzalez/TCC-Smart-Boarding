package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "email can't be empty") @Email @Size(max = 100) String email,
        @NotBlank(message = "password can't be empty") @Size(min = 6) String password,
        @NotNull(message = "role can't be null") Role role,
        @NotBlank(message = "full name can't be empty") @Size(max = 150) String fullName
) {}
