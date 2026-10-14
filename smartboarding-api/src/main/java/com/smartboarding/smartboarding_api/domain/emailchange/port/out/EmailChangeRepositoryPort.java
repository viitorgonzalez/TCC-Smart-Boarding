package com.smartboarding.smartboarding_api.domain.emailchange.port.out;

import com.smartboarding.smartboarding_api.domain.emailchange.entity.EmailChangeRequest;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface EmailChangeRepositoryPort {

    EmailChangeRequest save(EmailChangeRequest request);

    Optional<EmailChangeRequest> findLatestOpenByUserId(UUID userId);

    void invalidateAllForUser(UUID userId, LocalDateTime at);
}
