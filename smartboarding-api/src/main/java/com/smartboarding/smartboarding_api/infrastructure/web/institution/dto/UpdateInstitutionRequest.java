package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import jakarta.validation.constraints.Size;

/// Campos nulos ficam como estão.
public record UpdateInstitutionRequest(
        @Size(max = 150) String name,
        @Size(max = 255) String address,
        Double latitude,
        Double longitude
) {}
