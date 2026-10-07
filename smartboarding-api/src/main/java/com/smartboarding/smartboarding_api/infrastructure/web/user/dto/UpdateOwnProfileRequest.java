package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Size;

public record UpdateOwnProfileRequest(
        @Size(max = 20) String phone,
        @Size(max = 100) String course
) {}
