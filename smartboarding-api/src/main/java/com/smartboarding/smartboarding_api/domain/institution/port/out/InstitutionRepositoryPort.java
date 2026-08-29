package com.smartboarding.smartboarding_api.domain.institution.port.out;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InstitutionRepositoryPort {
    Institution save(Institution institution);
    Optional<Institution> findById(UUID id);
    List<Institution> findAll();
    void deleteById(UUID id);
}
