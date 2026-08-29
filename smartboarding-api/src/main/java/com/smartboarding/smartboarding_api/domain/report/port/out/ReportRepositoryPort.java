package com.smartboarding.smartboarding_api.domain.report.port.out;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;
import java.util.UUID;

public interface ReportRepositoryPort {
    Report save(Report report);
    Optional<Report> findById(UUID id);
    Page<Report> findAll(Pageable pageable);
    Optional<Report> findByDailyListId(UUID dailyListId);
}
