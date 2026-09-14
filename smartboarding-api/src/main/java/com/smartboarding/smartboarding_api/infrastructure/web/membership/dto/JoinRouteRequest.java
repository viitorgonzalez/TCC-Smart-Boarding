package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record JoinRouteRequest(
        @NotBlank(message = "informe o código da rota")
        @Size(max = 16, message = "código inválido")
        String code
) {}
