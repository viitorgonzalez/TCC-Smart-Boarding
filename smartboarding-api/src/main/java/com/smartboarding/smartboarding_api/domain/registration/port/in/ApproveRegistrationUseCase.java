package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.util.UUID;

public interface ApproveRegistrationUseCase {
    User approve(UUID id);
}
