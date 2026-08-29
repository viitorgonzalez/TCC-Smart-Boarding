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
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.service.VehicleAllocator;
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
    private final VehicleRepositoryPort vehicleRepository;

    public ReportUseCaseImpl(ReportRepositoryPort reportRepository,
                             ListEntryRepositoryPort listEntryRepository,
                             ObjectMapper objectMapper,
                             VehicleRepositoryPort vehicleRepository) {
        this.reportRepository = reportRepository;
        this.listEntryRepository = listEntryRepository;
        this.objectMapper = objectMapper;
        this.vehicleRepository = vehicleRepository;
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
        // Relatório é imutável e um por lista (RN8). Sem esta guarda, uma lista
        // reaberta e fechada de novo geraria um segundo relatório e as leituras
        // por lista passariam a encontrar mais de um resultado.
        var existing = reportRepository.findByDailyListId(dailyList.getId());
        if (existing.isPresent()) {
            log.info("Relatório da lista {} já existe, mantendo o original", dailyList.getId());
            return existing.get();
        }

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

        // RN16: o veículo proposto sai da quantidade real de inscritos no
        // fechamento — é o que transforma a capacidade cadastrada em decisão.
        var allocation = VehicleAllocator.allocate(
                vehicleRepository.findAllByRouteId(dailyList.getRoute().getId()), entries.size());
        String proposedJson;
        try {
            proposedJson = objectMapper.writeValueAsString(allocation.vehicles().stream()
                    .map(v -> Map.of("label", v.getLabel(), "capacity", String.valueOf(v.getCapacity())))
                    .toList());
        } catch (JsonProcessingException ex) {
            log.error("Erro ao serializar veículos propostos: {}", ex.getMessage());
            proposedJson = "[]";
        }

        Report report = Report.builder()
                .dailyList(dailyList)
                .totalEntries(entries.size())
                .snapshotData(snapshotJson)
                .proposedVehicles(proposedJson)
                .capacityShortfall(allocation.shortfall())
                .build();

        Report saved = reportRepository.save(report);
        log.info("Relatório gerado para lista {} com {} inscritos", dailyList.getId(), entries.size());
        return saved;
    }
}
