package com.smartboarding.smartboarding_api.infrastructure.web.list;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import com.smartboarding.smartboarding_api.domain.stop.StudentStop;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.service.VehicleAllocator;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.ListResponse;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import java.util.stream.Collectors;

/// Monta a `ListResponse`, que junta dados de cinco repositórios diferentes.
///
/// Fora do controller porque ele passou do limite de 300 linhas que o CI cobra,
/// e porque a montagem é a parte que cresce: cada campo novo na resposta
/// (tempo de viagem, veículo proposto, divisão por instituição) chega aqui, não
/// no roteamento. O controller fica com rota, guard e status HTTP.
@Component
public class ListResponseAssembler {

    private final ListEntryRepositoryPort listEntryRepository;
    private final UserRepositoryPort userRepository;
    private final VehicleRepositoryPort vehicleRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final ReportRepositoryPort reportRepository;
    private final ObjectMapper objectMapper;
    private final ManageStopsUseCase manageStopsUseCase;

    public ListResponseAssembler(ListEntryRepositoryPort listEntryRepository,
                                 UserRepositoryPort userRepository,
                                 VehicleRepositoryPort vehicleRepository,
                                 InstitutionRepositoryPort institutionRepository,
                                 ReportRepositoryPort reportRepository,
                                 ObjectMapper objectMapper,
                                 ManageStopsUseCase manageStopsUseCase) {
        this.listEntryRepository = listEntryRepository;
        this.userRepository = userRepository;
        this.vehicleRepository = vehicleRepository;
        this.institutionRepository = institutionRepository;
        this.reportRepository = reportRepository;
        this.objectMapper = objectMapper;
        this.manageStopsUseCase = manageStopsUseCase;
    }

    public Map<UUID, String> institutionNames() {
        return institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));
    }

    public User userOf(UUID userId) {
        return userRepository.findById(userId).orElse(null);
    }

    public ListResponse assemble(DailyList list, UUID userId, Map<UUID, String> names) {
        return assemble(list, userId, names, userOf(userId));
    }

    /// [quem] resolvido uma vez pelo chamador: buscá-lo aqui dentro faria uma
    /// consulta por lista, e o admin com vinte listas do dia pagaria vinte
    /// buscas do mesmo usuário.
    public ListResponse assemble(DailyList list, UUID userId, Map<UUID, String> names, User quem) {
        long confirmados = listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId());
        ProposedInfo proposta = proposedOf(list, confirmados);
        List<Stop> paradas = manageStopsUseCase.listByRoute(list.getRoute().getId());
        return ListResponse.from(
                list,
                confirmados,
                listEntryRepository.findByUserIdAndDailyListId(userId, list.getId()).orElse(null),
                entriesByInstitution(list.getId(), names),
                vehiclesOf(list.getRoute().getId()),
                proposta.vehicles(),
                proposta.shortfall(),
                stopsOf(paradas),
                myTripTime(quem, paradas));
    }

    private List<ListResponse.InstitutionCount> entriesByInstitution(UUID listId, Map<UUID, String> names) {
        return listEntryRepository.findAllByDailyListIdAndIsActiveTrue(listId).stream()
                .collect(Collectors.groupingBy(
                        entry -> names.getOrDefault(entry.getUser().getInstitutionId(), "Sem instituição"),
                        TreeMap::new,
                        Collectors.counting()))
                .entrySet().stream()
                .map(e -> new ListResponse.InstitutionCount(e.getKey(), e.getValue()))
                .toList();
    }

    /// Nulo pro admin: ele conduz o ônibus, não desce em lugar nenhum. Nulo
    /// também quando o tempo ainda não foi calculado -- e aí a tela omite, em
    /// vez de mostrar um zero que o aluno leria como "chega na hora".
    private ListResponse.MyTripTime myTripTime(User quem, List<Stop> paradas) {
        if (quem == null || quem.getRole() != Role.STUDENT) return null;

        StudentStop dele = StudentStop.resolve(paradas, quem.getInstitutionId());
        if (dele == null || dele.stop().getAvgMinutesFromStart() == null) return null;

        return new ListResponse.MyTripTime(dele.stop().getName(),
                dele.stop().getAvgMinutesFromStart(), dele.fallback());
    }

    /// Fechada, vem do relatório gravado: ali a decisão está congelada e é o
    /// que de fato foi usado no dia.
    private ProposedInfo proposedOf(DailyList list, long confirmados) {
        if (list.getStatus() != ListStatus.CLOSED) {
            return alocacaoAoVivo(list, confirmados);
        }
        return reportRepository.findByDailyListId(list.getId())
                .map(report -> {
                    try {
                        List<Map<String, String>> raw = objectMapper.readValue(
                                report.getProposedVehicles() == null ? "[]" : report.getProposedVehicles(),
                                new TypeReference<>() {});
                        return new ProposedInfo(raw.stream()
                                .map(v -> new ListResponse.VehicleSummary(
                                        v.get("label"), Integer.parseInt(v.get("capacity"))))
                                .toList(), report.getCapacityShortfall());
                    } catch (Exception e) {
                        return new ProposedInfo(List.of(), report.getCapacityShortfall());
                    }
                })
                .orElseGet(() -> alocacaoAoVivo(list, confirmados));
    }

    private ProposedInfo alocacaoAoVivo(DailyList list, long confirmados) {
        var frota = vehicleRepository.findAllByRouteId(list.getRoute().getId());
        var alocacao = VehicleAllocator.allocate(frota, (int) confirmados);
        return new ProposedInfo(
                alocacao.vehicles().stream()
                        .map(v -> new ListResponse.VehicleSummary(v.getLabel(), v.getCapacity()))
                        .toList(),
                alocacao.shortfall());
    }

    private record ProposedInfo(List<ListResponse.VehicleSummary> vehicles, int shortfall) {}

    private List<ListResponse.StopPoint> stopsOf(List<Stop> paradas) {
        return paradas.stream()
                .map(s -> new ListResponse.StopPoint(
                        s.getName(), s.getLatitude(), s.getLongitude(), s.getSequence()))
                .toList();
    }

    private List<ListResponse.VehicleSummary> vehiclesOf(UUID routeId) {
        return vehicleRepository.findAllByRouteId(routeId).stream()
                .map(v -> new ListResponse.VehicleSummary(v.getLabel(), v.getCapacity()))
                .toList();
    }
}
