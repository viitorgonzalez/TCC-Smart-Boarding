package com.smartboarding.smartboarding_api.domain.notification.port.out;

import java.util.List;

public interface FcmPort {
    void sendToTokens(List<String> tokens, String title, String body);
}
