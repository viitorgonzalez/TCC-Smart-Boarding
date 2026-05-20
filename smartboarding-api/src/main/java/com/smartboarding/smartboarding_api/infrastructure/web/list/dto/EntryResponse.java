package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;

import java.time.LocalDateTime;
import java.util.UUID;

public record EntryResponse(UUID id, UUID userId, String fullName, String email, LocalDateTime createdAt) {
    public static EntryResponse from(ListEntry entry) {
        return new EntryResponse(
                entry.getId(),
                entry.getUser().getId(),
                entry.getUser().getFullName(),
                entry.getUser().getEmail(),
                entry.getCreatedAt()
        );
    }
}
