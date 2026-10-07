package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.AddressResponse;

import java.util.List;
import java.util.UUID;

public record MeResponse(UUID id, String fullName, String email, String role,
                         boolean hasPassword, boolean hasGoogle,
                         String phone, String course, AddressResponse address,
                         List<String> missingForList, String institution) {

    public static MeResponse from(User user) {
        return from(user, null);
    }

    public static MeResponse from(User user, String institutionName) {
        return new MeResponse(user.getId(), user.getFullName(), user.getEmail(),
                user.getRole().name(), user.hasPassword(), user.hasGoogle(),
                user.getPhone(), user.getCourse(),
                AddressResponse.from(user.getAddress()),
                user.missingForList(), institutionName);
    }
}
