package com.smartboarding.smartboarding_api.DTO.auth;

import java.util.UUID;

public record RegisterResponseDTO(
        UUID id,
        String email
) {}
