package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface UserInstitutionJpaRepository extends JpaRepository<UserInstitution, UUID> {
    List<UserInstitution> findAllByUserId(UUID userId);

    boolean existsByUserIdAndInstitutionId(UUID userId, UUID institutionId);

    void deleteByUserIdAndInstitutionId(UUID userId, UUID institutionId);
}
