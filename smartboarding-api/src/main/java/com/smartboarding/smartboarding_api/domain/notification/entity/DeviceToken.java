package com.smartboarding.smartboarding_api.domain.notification.entity;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeviceToken {
    private UUID id;
    private User user;
    private String token;
    private String platform;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
