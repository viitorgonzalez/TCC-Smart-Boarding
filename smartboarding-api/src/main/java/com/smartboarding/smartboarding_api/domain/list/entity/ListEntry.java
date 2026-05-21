package com.smartboarding.smartboarding_api.domain.list.entity;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ListEntry {
    private UUID id;
    private User user;
    private DailyList dailyList;
    private LocalDateTime createdAt;
    private boolean isActive;
}
