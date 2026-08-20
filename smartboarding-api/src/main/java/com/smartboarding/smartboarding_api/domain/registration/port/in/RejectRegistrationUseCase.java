package com.smartboarding.smartboarding_api.domain.registration.port.in;

import java.util.UUID;

public interface RejectRegistrationUseCase {
    void reject(UUID id);
}
