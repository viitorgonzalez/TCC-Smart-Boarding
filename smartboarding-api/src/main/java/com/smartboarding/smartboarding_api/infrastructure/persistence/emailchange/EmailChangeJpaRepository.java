package com.smartboarding.smartboarding_api.infrastructure.persistence.emailchange;

import com.smartboarding.smartboarding_api.domain.emailchange.entity.EmailChangeRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface EmailChangeJpaRepository extends JpaRepository<EmailChangeRequest, UUID> {

    Optional<EmailChangeRequest> findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId);

    @Modifying
    @Query("UPDATE EmailChangeRequest r SET r.usedAt = :at WHERE r.userId = :userId AND r.usedAt IS NULL")
    void invalidateAllForUser(@Param("userId") UUID userId, @Param("at") LocalDateTime at);
}
