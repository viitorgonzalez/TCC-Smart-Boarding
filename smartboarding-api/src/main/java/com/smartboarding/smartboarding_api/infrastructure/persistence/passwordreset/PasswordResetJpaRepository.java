package com.smartboarding.smartboarding_api.infrastructure.persistence.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetJpaRepository extends JpaRepository<PasswordResetRequest, UUID> {

    Optional<PasswordResetRequest> findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId);

    @Modifying
    @Query("UPDATE PasswordResetRequest r SET r.usedAt = :at WHERE r.userId = :userId AND r.usedAt IS NULL")
    void invalidateAllForUser(@Param("userId") UUID userId, @Param("at") LocalDateTime at);
}
