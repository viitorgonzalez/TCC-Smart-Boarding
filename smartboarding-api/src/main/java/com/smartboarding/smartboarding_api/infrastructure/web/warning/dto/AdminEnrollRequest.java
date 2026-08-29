package com.smartboarding.smartboarding_api.infrastructure.web.warning.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record AdminEnrollRequest(
        @NotNull UUID userId,
        TripType tripType,
        /// Escolha do admin: nem toda inclusão tardia é falta do aluno.
        boolean issueWarning,
        @Size(max = 500) String warningReason
) {}
