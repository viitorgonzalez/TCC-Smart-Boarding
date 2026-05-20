package com.smartboarding.smartboarding_api.infrastructure.persistence.report;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public class ReportRepositoryAdapter implements ReportRepositoryPort {

    private final ReportJpaRepository jpa;

    public ReportRepositoryAdapter(ReportJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public Report save(Report report) { return jpa.save(report); }
    @Override public Optional<Report> findById(UUID id) { return jpa.findById(id); }
    @Override public Page<Report> findAll(Pageable pageable) { return jpa.findAll(pageable); }
}
