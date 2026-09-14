package com.smartboarding.smartboarding_api.infrastructure.persistence.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProfileUpdateRequestJpaRepository
        extends JpaRepository<ProfileUpdateRequest, UUID> {

    Optional<ProfileUpdateRequest> findByUserIdAndStatus(UUID userId, ProfileUpdateStatus status);

    List<ProfileUpdateRequest> findAllByStatusOrderByCreatedAtAsc(ProfileUpdateStatus status);

    List<ProfileUpdateRequest> findAllByUserIdOrderByCreatedAtDesc(UUID userId);
}
