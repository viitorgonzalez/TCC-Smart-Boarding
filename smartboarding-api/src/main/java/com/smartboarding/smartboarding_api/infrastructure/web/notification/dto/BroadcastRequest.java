package com.smartboarding.smartboarding_api.infrastructure.web.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record BroadcastRequest(
        @NotBlank(message = "title can't be empty") @Size(max = 150) String title,
        @NotBlank(message = "body can't be empty") String body,
        /// Todo aviso pertence a uma rota — quem recebe é quem pega aquela rota.
        @NotNull(message = "routeId is required") UUID routeId,
        /// Nulo = sem prazo de validade.
        @Positive Integer durationHours
) {}
