package com.smartboarding.smartboarding_api.domain.user.port.in;

import java.util.UUID;

public interface UpdateOwnProfileUseCase {
    void update(UUID userId, String phone, String course);
}
