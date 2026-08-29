package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.time.LocalDate;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String email,
        String fullName,
        Role role,
        String course,
        String institution,
        String phone,
        String address,
        LocalDate birthDate,
        LocalDate expiryDate,
        boolean isActive
) {
    public static UserResponse from(User user, String institutionName) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole(),
                user.getCourse(),
                institutionName,
                user.getPhone(),
                user.getAddress(),
                user.getBirthDate(),
                user.getExpiryDate(),
                user.isActive()
        );
    }
}
