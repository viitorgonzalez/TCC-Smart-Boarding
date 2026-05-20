package com.smartboarding.smartboarding_api.domain.notification.port.out;

import com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeviceTokenRepositoryPort {
    DeviceToken save(DeviceToken deviceToken);
    Optional<DeviceToken> findByUserIdAndToken(UUID userId, String token);
    List<DeviceToken> findByUserId(UUID userId);
    List<String> findAllTokens();
    void deleteByUserId(UUID userId);
}
