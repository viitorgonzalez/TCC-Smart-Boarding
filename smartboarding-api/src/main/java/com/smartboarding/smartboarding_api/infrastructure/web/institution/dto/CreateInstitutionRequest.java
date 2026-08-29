package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateInstitutionRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 150) String name,
        @Size(max = 255) String address,
        Double latitude,
        Double longitude,
        /// Rota que passa a atender a instituição. Nulo = sem rota ainda.
        java.util.UUID routeId
) {}
