package com.smartboarding.smartboarding_api.domain.membership.port.out;

import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;

import java.util.List;
import java.util.UUID;

public interface UserInstitutionRepositoryPort {
    UserInstitution save(UserInstitution link);

    List<UserInstitution> findAllByUserId(UUID userId);

    boolean existsByUserIdAndInstitutionId(UUID userId, UUID institutionId);

    void deleteByUserIdAndInstitutionId(UUID userId, UUID institutionId);
}
