package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

public interface SignupUseCase {
    User signup(User user, String rawPassword);
}
