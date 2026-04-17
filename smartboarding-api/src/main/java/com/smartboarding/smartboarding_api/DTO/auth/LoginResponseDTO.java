package com.smartboarding.smartboarding_api.DTO.auth;

public record LoginResponseDTO(
        String token,
        String fullName,
        String role
) {}
