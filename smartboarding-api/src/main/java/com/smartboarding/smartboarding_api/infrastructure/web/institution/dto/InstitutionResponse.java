package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.UUID;

public record InstitutionResponse(UUID id, String name, String address, Double latitude, Double longitude) {
    public static InstitutionResponse from(Institution institution) {
        return new InstitutionResponse(institution.getId(), institution.getName(),
                institution.getAddress(), institution.getLatitude(), institution.getLongitude());
    }
}
