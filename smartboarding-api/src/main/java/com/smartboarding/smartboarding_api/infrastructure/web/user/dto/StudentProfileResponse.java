package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record StudentProfileResponse(
        UUID id,
        String fullName,
        String email,
        String phone,
        AddressResponse address,
        LocalDate birthDate,
        String course,
        String institution,
        boolean isActive,
        String role,
        List<LocalDate> recentAttendance,
        List<StatusChange> statusHistory
) {
    public record StatusChange(String action, String adminName, LocalDateTime at) {}
}
