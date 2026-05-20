package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeviceTokenJpaRepository extends JpaRepository<DeviceToken, UUID> {
    Optional<DeviceToken> findByUserIdAndToken(UUID userId, String token);
    List<DeviceToken> findByUserId(UUID userId);
    void deleteByUserId(UUID userId);

    @Query("SELECT dt.token FROM DeviceToken dt")
    List<String> findAllTokens();
}
