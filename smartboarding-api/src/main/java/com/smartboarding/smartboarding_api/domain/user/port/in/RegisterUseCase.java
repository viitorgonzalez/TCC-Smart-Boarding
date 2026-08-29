package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

public interface RegisterUseCase {
    User execute(User user, String rawPassword);
}
