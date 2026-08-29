package com.smartboarding.smartboarding_api.infrastructure.persistence.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class InstitutionRepositoryAdapter implements InstitutionRepositoryPort {

    private final InstitutionJpaRepository jpa;

    public InstitutionRepositoryAdapter(InstitutionJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public Institution save(Institution institution) { return jpa.save(institution); }
    @Override public Optional<Institution> findById(UUID id) { return jpa.findById(id); }
    @Override public List<Institution> findAll() { return jpa.findAll(); }
}
