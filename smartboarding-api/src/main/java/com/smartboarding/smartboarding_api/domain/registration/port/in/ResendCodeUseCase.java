package com.smartboarding.smartboarding_api.domain.registration.port.in;

public interface ResendCodeUseCase {
    void resendCode(String email);
}
