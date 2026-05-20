package com.smartboarding.smartboarding_api.domain.notification.port.in;

import java.util.UUID;

public interface RegisterDeviceTokenUseCase {
    void execute(UUID userId, String token, String platform);
}
