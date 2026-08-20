package com.smartboarding.smartboarding_api.infrastructure.persistence.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface InstitutionJpaRepository extends JpaRepository<Institution, UUID> {}
