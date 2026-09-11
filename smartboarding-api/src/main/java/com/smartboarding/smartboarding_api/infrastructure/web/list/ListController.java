package com.smartboarding.smartboarding_api.infrastructure.web.list;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.in.AddEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.RemoveEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.EntryRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.AttendanceResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.CreateListRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.UpdateListStatusRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.EntryResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.list.dto.ListResponse;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import com.smartboarding.smartboarding_api.domain.warning.port.in.EnrollByAdminUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.warning.dto.AdminEnrollRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.stream.Collectors;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/lists")
public class ListController {

    private final FindListUseCase findListUseCase;
    private final AddEntryUseCase addEntryUseCase;
    private final RemoveEntryUseCase removeEntryUseCase;
    private final ListEntryRepositoryPort listEntryRepository;
    private final UserRepositoryPort userRepository;
    private final VehicleRepositoryPort vehicleRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort reportRepository;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;
    private final com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase manageStopsUseCase;
    private final com.smartboarding.smartboarding_api.domain.list.port.in.ManageDailyListUseCase manageDailyListUseCase;
    private final EnrollByAdminUseCase enrollByAdminUseCase;

    public ListController(FindListUseCase findListUseCase,
                          AddEntryUseCase addEntryUseCase,
                          RemoveEntryUseCase removeEntryUseCase,
                          ListEntryRepositoryPort listEntryRepository,
                          UserRepositoryPort userRepository,
                          VehicleRepositoryPort vehicleRepository,
                          InstitutionRepositoryPort institutionRepository,
                          com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort reportRepository,
                          com.fasterxml.jackson.databind.ObjectMapper objectMapper,
                          com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase manageStopsUseCase,
                          com.smartboarding.smartboarding_api.domain.list.port.in.ManageDailyListUseCase manageDailyListUseCase,
                          EnrollByAdminUseCase enrollByAdminUseCase) {
        this.findListUseCase = findListUseCase;
        this.addEntryUseCase = addEntryUseCase;
        this.removeEntryUseCase = removeEntryUseCase;
        this.listEntryRepository = listEntryRepository;
        this.userRepository = userRepository;
        this.vehicleRepository = vehicleRepository;
        this.institutionRepository = institutionRepository;
        this.reportRepository = reportRepository;
        this.objectMapper = objectMapper;
        this.manageStopsUseCase = manageStopsUseCase;
        this.manageDailyListUseCase = manageDailyListUseCase;
        this.enrollByAdminUseCase = enrollByAdminUseCase;
    }

    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<ListResponse>>> getTodayLists(Authentication auth) {
        UUID userId = extractUserId(auth);
        Map<UUID, String> names = institutionNames();
        List<ListResponse> lists = findListUseCase.findTodayLists(userId).stream()
                .map(list -> ListResponse.from(
                        list,
                        listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId()),
                        listEntryRepository.findByUserIdAndDailyListId(userId, list.getId()).orElse(null),
                        entriesByInstitution(list.getId(), names),
                        vehiclesOf(list.getRoute().getId()),
                        proposedOf(list).vehicles(),
                        proposedOf(list).shortfall(),
                        stopsOf(list.getRoute().getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(lists));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ListResponse>>> byDate(
            @RequestParam LocalDate date, Authentication auth) {
        UUID userId = extractUserId(auth);
        Map<UUID, String> names = institutionNames();
        List<ListResponse> lists = manageDailyListUseCase.findByDate(date).stream()
                .map(list -> ListResponse.from(
                        list,
                        listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId()),
                        listEntryRepository.findByUserIdAndDailyListId(userId, list.getId()).orElse(null),
                        entriesByInstitution(list.getId(), names),
                        vehiclesOf(list.getRoute().getId()),
                        proposedOf(list).vehicles(),
                        proposedOf(list).shortfall(),
                        stopsOf(list.getRoute().getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(lists));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<?>> create(@RequestBody @Valid CreateListRequest request) {
        var created = manageDailyListUseCase.create(request.routeId(), request.date());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(Map.of("id", created.getId().toString())));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> updateStatus(@PathVariable UUID id,
                                                       @RequestBody @Valid UpdateListStatusRequest request) {
        manageDailyListUseCase.setStatus(id, request.status(), request.reason());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID id) {
        manageDailyListUseCase.delete(id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @GetMapping("/my-attendance")
    public ResponseEntity<ApiResponse<List<AttendanceResponse>>> myAttendance(
            @RequestParam(defaultValue = "6") int months, Authentication auth) {
        List<AttendanceResponse> days = findListUseCase
                .findMyAttendance(extractUserId(auth), months).stream()
                .map(AttendanceResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(days));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ListResponse>> findById(@PathVariable UUID id, Authentication auth) {
        UUID userId = extractUserId(auth);
        DailyList list = findListUseCase.findById(id);
        long count = listEntryRepository.countByDailyListIdAndIsActiveTrue(id);
        return ResponseEntity.ok(ApiResponse.data(ListResponse.from(
                list, count, listEntryRepository.findByUserIdAndDailyListId(userId, id).orElse(null),
                entriesByInstitution(id, institutionNames()),
                vehiclesOf(list.getRoute().getId()),
                proposedOf(list).vehicles(),
                proposedOf(list).shortfall(),
                stopsOf(list.getRoute().getId()))));
    }

    @PostMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<EntryResponse>> addEntry(
            @PathVariable UUID id,
            @RequestBody(required = false) EntryRequest body,
            Authentication auth) {
        UUID userId = extractUserId(auth);
        TripType tripType = (body != null && body.tripType() != null) ? body.tripType() : TripType.ROUND_TRIP;
        var saved = addEntryUseCase.add(userId, id, tripType);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                EntryResponse.from(saved, institutionNames().get(saved.getUser().getInstitutionId()), true)));
    }

    /// Inclusão tardia: entra mesmo com a lista fechada, e o admin decide se
    /// isso gera advertência pro aluno.
    @PostMapping("/{id}/entries/admin")
    public ResponseEntity<ApiResponse<EntryResponse>> addEntryAsAdmin(
            @PathVariable UUID id,
            @RequestBody @Valid AdminEnrollRequest body,
            Authentication auth) {
        TripType tripType = body.tripType() != null ? body.tripType() : TripType.ROUND_TRIP;
        var saved = enrollByAdminUseCase.enroll(id, body.userId(), tripType,
                body.issueWarning(), body.warningReason(), extractUserId(auth));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                EntryResponse.from(saved, institutionNames().get(saved.getUser().getInstitutionId()), true)));
    }

    /// Remoção pelo admin: tirar quem ele mesmo incluiu não pode depender do
    /// horário da lista.
    @DeleteMapping("/{id}/entries/{userId}")
    public ResponseEntity<ApiResponse<?>> removeEntryAsAdmin(@PathVariable UUID id,
                                                             @PathVariable UUID userId) {
        removeEntryUseCase.remove(userId, id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @DeleteMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<?>> removeEntry(@PathVariable UUID id, Authentication auth) {
        UUID userId = extractUserId(auth);
        removeEntryUseCase.remove(userId, id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @GetMapping("/{id}/entries")
    public ResponseEntity<ApiResponse<List<EntryResponse>>> getEntries(@PathVariable UUID id,
                                                                       Authentication auth) {
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
        Map<UUID, String> names = institutionNames();
        List<EntryResponse> entries = findListUseCase.findEntriesByList(id).stream()
                .map(entry -> EntryResponse.from(
                        entry, names.get(entry.getUser().getInstitutionId()), isAdmin))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(entries));
    }


    /// Nome da instituição por id — um mapa só, pra não fazer um findById por inscrito.
    private Map<UUID, String> institutionNames() {
        return institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));
    }

    private List<ListResponse.InstitutionCount> entriesByInstitution(UUID listId, Map<UUID, String> names) {
        return listEntryRepository.findAllByDailyListIdAndIsActiveTrue(listId).stream()
                .collect(Collectors.groupingBy(
                        entry -> names.getOrDefault(entry.getUser().getInstitutionId(), "Sem instituição"),
                        java.util.TreeMap::new,
                        Collectors.counting()))
                .entrySet().stream()
                .map(e -> new ListResponse.InstitutionCount(e.getKey(), e.getValue()))
                .toList();
    }

    /// Veículo proposto vem do relatório gravado no fechamento (RN16). Lista
    /// aberta ainda não tem proposta — o total de confirmados muda até fechar.
    private ProposedInfo proposedOf(DailyList list) {
        if (list.getStatus() != com.smartboarding.smartboarding_api.domain.list.entity.ListStatus.CLOSED) {
            return new ProposedInfo(List.of(), 0);
        }
        return reportRepository.findByDailyListId(list.getId())
                .map(report -> {
                    try {
                        List<Map<String, String>> raw = objectMapper.readValue(
                                report.getProposedVehicles() == null ? "[]" : report.getProposedVehicles(),
                                new com.fasterxml.jackson.core.type.TypeReference<>() {});
                        return new ProposedInfo(raw.stream()
                                .map(v -> new ListResponse.VehicleSummary(
                                        v.get("label"), Integer.parseInt(v.get("capacity"))))
                                .toList(), report.getCapacityShortfall());
                    } catch (Exception e) {
                        return new ProposedInfo(List.of(), report.getCapacityShortfall());
                    }
                })
                .orElseGet(() -> new ProposedInfo(List.of(), 0));
    }

    private record ProposedInfo(List<ListResponse.VehicleSummary> vehicles, int shortfall) {}

    private List<ListResponse.StopPoint> stopsOf(UUID routeId) {
        return manageStopsUseCase.listByRoute(routeId).stream()
                .map(s -> new ListResponse.StopPoint(
                        s.getName(), s.getLatitude(), s.getLongitude(), s.getSequence()))
                .toList();
    }

    private List<ListResponse.VehicleSummary> vehiclesOf(UUID routeId) {
        return vehicleRepository.findAllByRouteId(routeId).stream()
                .map(v -> new ListResponse.VehicleSummary(v.getLabel(), v.getCapacity()))
                .toList();
    }

    private UUID extractUserId(Authentication auth) {
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
