package com.smartboarding.smartboarding_api.infrastructure.web.route.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalTime;

public record UpdateScheduleRequest(
        @NotNull LocalTime openTime,
        @NotNull LocalTime closeTime,
        /// Vai no aviso enviado aos alunos da rota.
        @Size(max = 500) String reason
) {}
