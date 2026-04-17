package com.smartboarding.smartboarding_api.DTO;

import com.smartboarding.smartboarding_api.Enums.Role;
import com.smartboarding.smartboarding_api.Models.User;

import java.time.LocalDate;
import java.util.UUID;

public record UserDTO(
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
    public static UserDTO fromEntity(User user) {
        return new UserDTO(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole(),
                user.getCourse(),
                user.getInstitution(),
                user.getPhone(),
                user.getAddress(),
                user.getBirthDate(),
                user.getExpiryDate(),
                user.isActive()
        );
    }
}
