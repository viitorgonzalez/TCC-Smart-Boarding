package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

public interface GoogleSignInUseCase {
    /// Entra com o ID token do Google. Cria a conta na primeira vez.
    User signIn(String idToken);
}
