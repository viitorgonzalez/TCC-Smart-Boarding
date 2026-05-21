package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeviceTokenJpaRepository extends JpaRepository<DeviceTokenJpaEntity, UUID> {
    Optional<DeviceTokenJpaEntity> findByUserIdAndToken(UUID userId, String token);
    List<DeviceTokenJpaEntity> findByUserId(UUID userId);
    void deleteByUserId(UUID userId);

    @Query("SELECT dt.token FROM DeviceTokenJpaEntity dt")
    List<String> findAllTokens();
}
