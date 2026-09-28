package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Size;

/// Campo ausente = não foi pedida mudança nele; string em branco = pedido pra
/// limpar. Por isso nada é @NotBlank.
public record UpdateOwnProfileRequest(
        @Size(max = 20) String phone,
        @Size(max = 100) String course
) {}
