package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/// Sem horário de propósito: mexer na janela da lista exige motivo e dispara
/// aviso à rota, então tem endpoint próprio (`PATCH /api/routes/{id}/schedule`).
public record UpdateRouteRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 100) String name,
        @Size(max = 255) String description,
        /// Nulo mantém o estado atual. Existe pra desfazer o soft-delete do
        /// DELETE, que antes não tinha caminho de volta.
        Boolean isActive
) {}
