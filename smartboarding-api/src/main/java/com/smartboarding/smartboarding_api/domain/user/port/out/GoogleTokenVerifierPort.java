package com.smartboarding.smartboarding_api.domain.user.port.out;

public interface GoogleTokenVerifierPort {

    record GoogleAccount(String googleId, String email, String fullName, boolean emailVerified) {}

    GoogleAccount verify(String idToken);
}
