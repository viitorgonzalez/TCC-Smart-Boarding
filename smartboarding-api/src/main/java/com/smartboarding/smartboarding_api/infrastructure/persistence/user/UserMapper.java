package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

public class UserMapper {

    public static User toDomain(UserJpaEntity e) {
        if (e == null) return null;
        return User.builder()
                .id(e.getId())
                .email(e.getEmail())
                .password(e.getPassword())
                .role(e.getRole())
                .fullName(e.getFullName())
                .birthDate(e.getBirthDate())
                .course(e.getCourse())
                .institution(e.getInstitution())
                .phone(e.getPhone())
                .address(e.getAddress())
                .expiryDate(e.getExpiryDate())
                .createdAt(e.getCreatedAt())
                .updatedAt(e.getUpdatedAt())
                .isActive(e.isActive())
                .build();
    }

    public static UserJpaEntity toJpa(User u) {
        if (u == null) return null;
        return UserJpaEntity.builder()
                .id(u.getId())
                .email(u.getEmail())
                .password(u.getPassword())
                .role(u.getRole())
                .fullName(u.getFullName())
                .birthDate(u.getBirthDate())
                .course(u.getCourse())
                .institution(u.getInstitution())
                .phone(u.getPhone())
                .address(u.getAddress())
                .expiryDate(u.getExpiryDate())
                .createdAt(u.getCreatedAt())
                .updatedAt(u.getUpdatedAt())
                .isActive(u.isActive())
                .build();
    }
}
