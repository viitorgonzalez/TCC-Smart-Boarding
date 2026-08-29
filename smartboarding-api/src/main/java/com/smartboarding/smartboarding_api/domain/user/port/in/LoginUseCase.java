package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.application.user.AuthToken;

public interface LoginUseCase {
    AuthToken execute(String email, String password);
}
