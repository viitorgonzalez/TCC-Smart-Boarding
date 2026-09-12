package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Repository
public class UserInstitutionRepositoryAdapter implements UserInstitutionRepositoryPort {

    private final UserInstitutionJpaRepository jpa;

    public UserInstitutionRepositoryAdapter(UserInstitutionJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public UserInstitution save(UserInstitution link) { return jpa.save(link); }
    @Override public List<UserInstitution> findAllByUserId(UUID userId) {
        return jpa.findAllByUserIdOrderByCreatedAtAscIdAsc(userId);
    }
    @Override public boolean existsByUserIdAndInstitutionId(UUID userId, UUID institutionId) {
        return jpa.existsByUserIdAndInstitutionId(userId, institutionId);
    }

    @Override
    @Transactional
    public void deleteByUserIdAndInstitutionId(UUID userId, UUID institutionId) {
        jpa.deleteByUserIdAndInstitutionId(userId, institutionId);
    }
}
