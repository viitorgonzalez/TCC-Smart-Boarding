package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

public record InviteInfoResponse(String email) {
    public static InviteInfoResponse from(RegistrationRequest request) {
        return new InviteInfoResponse(request.getEmail());
    }
}
