package com.smartboarding.smartboarding_api.domain.profile.port.in;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ManageProfileUpdateUseCase {
    ProfileUpdateRequest request(UUID userId, ProfileUpdateRequest pedido);

    Optional<ProfileUpdateRequest> myPending(UUID userId);

    Optional<ProfileUpdateRequest> myLatest(UUID userId);

    List<ProfileUpdateRequest> listPending();

    List<ProfileUpdateRequest> listAll(String status);

    ProfileUpdateRequest approve(UUID requestId, UUID adminId);

    ProfileUpdateRequest reject(UUID requestId, String reason, UUID adminId);
}
