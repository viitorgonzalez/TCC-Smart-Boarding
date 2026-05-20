package com.smartboarding.smartboarding_api.infrastructure.persistence.report;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ReportJpaRepository extends JpaRepository<Report, UUID> {}
