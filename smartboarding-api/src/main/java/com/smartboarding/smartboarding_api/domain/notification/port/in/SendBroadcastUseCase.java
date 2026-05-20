package com.smartboarding.smartboarding_api.domain.notification.port.in;

public interface SendBroadcastUseCase {
    void execute(String title, String body);
}
