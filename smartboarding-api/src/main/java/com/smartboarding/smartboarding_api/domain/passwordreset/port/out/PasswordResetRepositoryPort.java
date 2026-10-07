package com.smartboarding.smartboarding_api.domain.passwordreset.port.out;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetRepositoryPort {

    PasswordResetRequest save(PasswordResetRequest request);

    Optional<PasswordResetRequest> findLatestOpenByUserId(UUID userId);

    void invalidateAllForUser(UUID userId, LocalDateTime at);
}
