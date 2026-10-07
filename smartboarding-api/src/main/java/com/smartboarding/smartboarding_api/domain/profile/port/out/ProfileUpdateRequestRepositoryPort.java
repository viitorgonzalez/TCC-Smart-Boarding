package com.smartboarding.smartboarding_api.domain.profile.port.out;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProfileUpdateRequestRepositoryPort {
    ProfileUpdateRequest save(ProfileUpdateRequest request);

    Optional<ProfileUpdateRequest> findById(UUID id);

    Optional<ProfileUpdateRequest> findPendingByUserId(UUID userId);

    List<ProfileUpdateRequest> findAllPending();

    List<ProfileUpdateRequest> findAllByStatusOrAll(ProfileUpdateStatus status);

    List<ProfileUpdateRequest> findAllByUserId(UUID userId);
}
