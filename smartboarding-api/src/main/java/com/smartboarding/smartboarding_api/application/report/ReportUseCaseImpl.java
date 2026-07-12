package com.smartboarding.smartboarding_api.application.report;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import com.smartboarding.smartboarding_api.domain.report.port.in.FindReportUseCase;
import com.smartboarding.smartboarding_api.domain.report.port.in.GenerateReportUseCase;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class ReportUseCaseImpl implements FindReportUseCase, GenerateReportUseCase {

    private final ReportRepositoryPort reportRepository;
    private final ListEntryRepositoryPort listEntryRepository;
    private final ObjectMapper objectMapper;

    public ReportUseCaseImpl(ReportRepositoryPort reportRepository,
                             ListEntryRepositoryPort listEntryRepository,
                             ObjectMapper objectMapper) {
        this.reportRepository = reportRepository;
        this.listEntryRepository = listEntryRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    public Page<Report> findAll(Pageable pageable) {
        return reportRepository.findAll(pageable);
    }

    @Override
    public Report findById(UUID id) {
        return reportRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Relatório não encontrado com ID: " + id));
    }

    @Override
    @Transactional
    public Report execute(DailyList dailyList) {
        List<ListEntry> entries = listEntryRepository.findAllByDailyListIdAndIsActiveTrue(dailyList.getId());

        List<Map<String, String>> snapshot = entries.stream()
                .map(e -> Map.of(
                        "id", e.getUser().getId().toString(),
                        "fullName", e.getUser().getFullName(),
                        "email", e.getUser().getEmail(),
                        "tripType", e.getTripType().name()
                ))
                .toList();

        String snapshotJson;
        try {
            snapshotJson = objectMapper.writeValueAsString(snapshot);
        } catch (JsonProcessingException ex) {
            log.error("Erro ao serializar snapshot do relatório: {}", ex.getMessage());
            snapshotJson = "[]";
        }

        Report report = Report.builder()
                .dailyList(dailyList)
                .totalEntries(entries.size())
                .snapshotData(snapshotJson)
                .build();

        Report saved = reportRepository.save(report);
        log.info("Relatório gerado para lista {} com {} inscritos", dailyList.getId(), entries.size());
        return saved;
    }
}
