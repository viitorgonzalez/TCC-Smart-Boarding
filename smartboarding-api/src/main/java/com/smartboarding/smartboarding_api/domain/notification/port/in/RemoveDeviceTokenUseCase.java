package com.smartboarding.smartboarding_api.domain.notification.port.in;

import java.util.UUID;

public interface RemoveDeviceTokenUseCase {
    void execute(UUID userId);
}
