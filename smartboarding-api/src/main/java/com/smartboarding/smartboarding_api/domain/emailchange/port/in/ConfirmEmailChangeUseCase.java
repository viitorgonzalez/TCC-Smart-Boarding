package com.smartboarding.smartboarding_api.domain.emailchange.port.in;

import java.util.UUID;

public interface ConfirmEmailChangeUseCase {

    void confirm(UUID userId, String code);
}
