package com.smartboarding.smartboarding_api.infrastructure.persistence.report;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ReportJpaRepository extends JpaRepository<ReportJpaEntity, UUID> {}
