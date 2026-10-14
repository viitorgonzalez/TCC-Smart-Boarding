package com.smartboarding.smartboarding_api.domain.passwordreset.port.in;

public interface RequestPasswordResetUseCase {

    void request(String email);
}
