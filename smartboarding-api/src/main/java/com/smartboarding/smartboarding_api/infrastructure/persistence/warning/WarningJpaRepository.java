package com.smartboarding.smartboarding_api.infrastructure.persistence.warning;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface WarningJpaRepository extends JpaRepository<Warning, UUID> {
    List<Warning> findAllByUserIdOrderByCreatedAtDesc(UUID userId);

    List<Warning> findAllByOrderByCreatedAtDesc();
}
