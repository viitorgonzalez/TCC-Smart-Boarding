package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken;
import com.smartboarding.smartboarding_api.domain.notification.port.out.DeviceTokenRepositoryPort;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class DeviceTokenRepositoryAdapter implements DeviceTokenRepositoryPort {

    private final DeviceTokenJpaRepository jpa;

    public DeviceTokenRepositoryAdapter(DeviceTokenJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public DeviceToken save(DeviceToken deviceToken) {
        return DeviceTokenMapper.toDomain(jpa.save(DeviceTokenMapper.toJpa(deviceToken)));
    }

    @Override
    public Optional<DeviceToken> findByUserIdAndToken(UUID userId, String token) {
        return jpa.findByUserIdAndToken(userId, token).map(DeviceTokenMapper::toDomain);
    }

    @Override
    public List<DeviceToken> findByUserId(UUID userId) {
        return jpa.findByUserId(userId).stream().map(DeviceTokenMapper::toDomain).toList();
    }

    @Override
    public List<String> findAllTokens() {
        return jpa.findAllTokens();
    }

    @Override
    @Transactional
    public void deleteByUserId(UUID userId) {
        jpa.deleteByUserId(userId);
    }
}
