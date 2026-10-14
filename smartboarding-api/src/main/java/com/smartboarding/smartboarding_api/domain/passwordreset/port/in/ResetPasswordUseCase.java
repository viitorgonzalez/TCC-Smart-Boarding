package com.smartboarding.smartboarding_api.domain.passwordreset.port.in;

public interface ResetPasswordUseCase {

    void reset(String email, String code, String newPassword);
}
