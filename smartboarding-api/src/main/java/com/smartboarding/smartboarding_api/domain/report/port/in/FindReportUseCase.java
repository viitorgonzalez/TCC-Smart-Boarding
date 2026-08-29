package com.smartboarding.smartboarding_api.domain.report.port.in;

import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

public interface FindReportUseCase {
    Page<Report> findAll(Pageable pageable);
    Report findById(UUID id);
}
