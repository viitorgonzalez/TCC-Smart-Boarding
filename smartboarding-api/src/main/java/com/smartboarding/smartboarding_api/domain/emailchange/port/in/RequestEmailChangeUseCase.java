package com.smartboarding.smartboarding_api.domain.emailchange.port.in;

import java.util.UUID;

public interface RequestEmailChangeUseCase {

    void request(UUID userId, String newEmail);
}
