package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

public interface ValidateTokenUseCase {
    RegistrationRequest validateToken(String token);
}
