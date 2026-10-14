package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

public interface GoogleSignInUseCase {
    User signIn(String idToken);
}
