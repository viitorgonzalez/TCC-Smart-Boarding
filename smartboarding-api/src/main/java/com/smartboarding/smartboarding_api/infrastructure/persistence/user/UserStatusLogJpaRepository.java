package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface UserStatusLogJpaRepository extends JpaRepository<UserStatusLog, UUID> {
    List<UserStatusLog> findAllByUserIdOrderByCreatedAtDesc(UUID userId);
}
