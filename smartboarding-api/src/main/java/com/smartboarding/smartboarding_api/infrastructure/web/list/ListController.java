package com.smartboarding.smartboarding_api.infrastructure.web.list;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.vehicle.service.VehicleAllocator;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.in.AddEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.RemoveEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.stop.StudentStop;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.shared.exception.ForbiddenException;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
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
    private final com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort
            routeMemberRepository;
    private final ListResponseAssembler assembler;

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
                          EnrollByAdminUseCase enrollByAdminUseCase,
                          com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort
                                  routeMemberRepository,
                          ListResponseAssembler assembler) {
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
        this.routeMemberRepository = routeMemberRepository;
        this.assembler = assembler;
    }

    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<ListResponse>>> getTodayLists(Authentication auth) {
        UUID userId = extractUserId(auth);
        User quem = assembler.userOf(userId);
        Map<UUID, String> names = assembler.institutionNames();
        List<ListResponse> lists = findListUseCase.findTodayLists(userId).stream()
                .map(list -> assembler.assemble(list, userId, names, quem))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(lists));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ListResponse>>> byDate(
            @RequestParam LocalDate date, Authentication auth) {
        UUID userId = extractUserId(auth);
        User quem = assembler.userOf(userId);
        Map<UUID, String> names = assembler.institutionNames();
        List<ListResponse> lists = manageDailyListUseCase.findByDate(date).stream()
                .map(list -> assembler.assemble(list, userId, names, quem))
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
        assertPodeLer(userId, list);
        return ResponseEntity.ok(ApiResponse.data(
                assembler.assemble(list, userId, assembler.institutionNames())));
    }

    private void assertPodeLer(UUID userId, DailyList list) {
        User quem = assembler.userOf(userId);
        if (quem == null || quem.getRole() == Role.ADMIN) return;
        if (!routeMemberRepository.existsByUserIdAndRouteId(userId, list.getRoute().getId())) {
            throw new ForbiddenException("NOT_IN_ROUTE",
                    "Você não faz parte da rota dessa lista.");
        }
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
                EntryResponse.from(saved, assembler.institutionNames().get(saved.getUser().getInstitutionId()), true)));
    }

    @PostMapping("/{id}/entries/admin")
    public ResponseEntity<ApiResponse<EntryResponse>> addEntryAsAdmin(
            @PathVariable UUID id,
            @RequestBody @Valid AdminEnrollRequest body,
            Authentication auth) {
        TripType tripType = body.tripType() != null ? body.tripType() : TripType.ROUND_TRIP;
        var saved = enrollByAdminUseCase.enroll(id, body.userId(), tripType,
                body.issueWarning(), body.warningReason(), extractUserId(auth));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                EntryResponse.from(saved, assembler.institutionNames().get(saved.getUser().getInstitutionId()), true)));
    }

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
        Map<UUID, String> names = assembler.institutionNames();
        List<EntryResponse> entries = findListUseCase.findEntriesByList(id).stream()
                .map(entry -> EntryResponse.from(
                        entry, names.get(entry.getUser().getInstitutionId()), isAdmin))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(entries));
    }


    private UUID extractUserId(Authentication auth) {
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
