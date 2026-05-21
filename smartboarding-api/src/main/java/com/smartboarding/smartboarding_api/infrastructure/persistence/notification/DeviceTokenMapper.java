package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken;
import com.smartboarding.smartboarding_api.infrastructure.persistence.user.UserMapper;

public class DeviceTokenMapper {

    public static DeviceToken toDomain(DeviceTokenJpaEntity e) {
        if (e == null) return null;
        return DeviceToken.builder()
                .id(e.getId())
                .user(UserMapper.toDomain(e.getUser()))
                .token(e.getToken())
                .platform(e.getPlatform())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .build();
    }

    public static DeviceTokenJpaEntity toJpa(DeviceToken d) {
        if (d == null) return null;
        return DeviceTokenJpaEntity.builder()
                .id(d.getId())
                .userId(d.getUser() != null ? d.getUser().getId() : null)
                .token(d.getToken())
                .platform(d.getPlatform())
                .createdAt(d.getCreatedAt())
                .updatedAt(d.getUpdatedAt())
                .build();
    }
}
