package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateInstitutionRequest(
        @NotBlank(message = "name can't be empty") String name,
        String address,
        Double latitude,
        Double longitude
) {}
