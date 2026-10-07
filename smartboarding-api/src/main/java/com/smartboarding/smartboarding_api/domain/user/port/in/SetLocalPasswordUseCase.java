package com.smartboarding.smartboarding_api.domain.user.port.in;

public interface SetLocalPasswordUseCase {
    void setPassword(java.util.UUID userId, String rawPassword);
}
