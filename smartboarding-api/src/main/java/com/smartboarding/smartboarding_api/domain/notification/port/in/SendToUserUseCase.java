package com.smartboarding.smartboarding_api.domain.notification.port.in;

import java.util.UUID;

public interface SendToUserUseCase {
    void execute(UUID userId, String title, String body);
}
