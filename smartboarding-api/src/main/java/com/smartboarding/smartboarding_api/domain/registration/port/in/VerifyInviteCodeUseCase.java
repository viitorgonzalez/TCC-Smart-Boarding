package com.smartboarding.smartboarding_api.domain.registration.port.in;

public interface VerifyInviteCodeUseCase {
    String verifyCode(String email, String code);
}
