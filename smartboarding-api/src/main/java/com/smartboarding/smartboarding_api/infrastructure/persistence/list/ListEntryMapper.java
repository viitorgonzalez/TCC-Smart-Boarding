package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.infrastructure.persistence.user.UserMapper;

public class ListEntryMapper {

    public static ListEntry toDomain(ListEntryJpaEntity e) {
        if (e == null) return null;
        return ListEntry.builder()
                .id(e.getId())
                .user(UserMapper.toDomain(e.getUser()))
                .dailyList(DailyListMapper.toDomain(e.getDailyList()))
                .createdAt(e.getCreatedAt())
                .isActive(e.isActive())
                .build();
    }

    public static ListEntryJpaEntity toJpa(ListEntry entry) {
        if (entry == null) return null;
        return ListEntryJpaEntity.builder()
                .id(entry.getId())
                .userId(entry.getUser() != null ? entry.getUser().getId() : null)
                .dailyListId(entry.getDailyList() != null ? entry.getDailyList().getId() : null)
                .createdAt(entry.getCreatedAt())
                .isActive(entry.isActive())
                .build();
    }
}
