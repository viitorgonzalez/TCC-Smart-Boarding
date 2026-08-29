package com.smartboarding.smartboarding_api.infrastructure.web.warning.dto;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;

import java.time.LocalDateTime;
import java.util.UUID;

public record WarningResponse(UUID id, UUID userId, String studentName, String reason,
                              String listDate, String issuedBy, LocalDateTime createdAt) {

    public static WarningResponse from(Warning w) {
        return new WarningResponse(
                w.getId(),
                w.getUser().getId(),
                w.getUser().getFullName(),
                w.getReason(),
                w.getDailyList() == null ? null : w.getDailyList().getDate().toString(),
                w.getIssuedBy() == null ? null : w.getIssuedBy().getFullName(),
                w.getCreatedAt());
    }
}
