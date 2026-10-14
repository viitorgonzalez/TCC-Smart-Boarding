package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

public record LoginResponse(String token, String fullName, String role, String email) {

    public static LoginResponse from(com.smartboarding.smartboarding_api.application.user.AuthToken token) {
        return new LoginResponse(token.token(), token.fullName(), token.role(), token.email());
    }
}
