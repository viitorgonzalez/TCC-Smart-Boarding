package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

public record LoginResponse(String token, String fullName, String role) {}
