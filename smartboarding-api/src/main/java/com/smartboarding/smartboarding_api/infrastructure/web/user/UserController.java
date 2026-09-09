package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;
import com.smartboarding.smartboarding_api.domain.user.port.in.FindUserUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.ManageUserStatusUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.StudentProfileResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UpdateUserStatusRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UserResponse;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final FindUserUseCase findUserUseCase;
    private final InstitutionRepositoryPort institutionRepository;
    private final ManageUserStatusUseCase manageUserStatusUseCase;
    private final UserRepositoryPort userRepository;
    private final ListEntryRepositoryPort listEntryRepository;

    /// Presenças do card cobrem os últimos 6 meses, o mesmo recorte do histórico
    /// que o aluno vê.
    private static final int ATTENDANCE_MONTHS = 6;

    public UserController(FindUserUseCase findUserUseCase,
                          InstitutionRepositoryPort institutionRepository,
                          ManageUserStatusUseCase manageUserStatusUseCase,
                          UserRepositoryPort userRepository,
                          ListEntryRepositoryPort listEntryRepository) {
        this.findUserUseCase = findUserUseCase;
        this.institutionRepository = institutionRepository;
        this.manageUserStatusUseCase = manageUserStatusUseCase;
        this.userRepository = userRepository;
        this.listEntryRepository = listEntryRepository;
    }

    /// [routeId] nulo devolve todos — o app usa o filtro por rota por padrão,
    /// mas a listagem completa continua acessível.
    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponse>>> listAll(
            @org.springframework.web.bind.annotation.RequestParam(required = false) UUID routeId) {
        // Um mapa único em vez de um findById por usuário — a listagem carrega
        // todo mundo e o N+1 apareceria já no primeiro uso real.
        Map<UUID, String> names = institutionNames();
        var source = routeId == null
                ? findUserUseCase.findAll()
                : findUserUseCase.findByRoute(routeId);
        List<UserResponse> users = source.stream()
                .map(user -> UserResponse.from(user, names.get(user.getInstitutionId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(users));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> findById(@PathVariable UUID id) {
        User user = findUserUseCase.findById(id);
        return ResponseEntity.ok(ApiResponse.data(
                UserResponse.from(user, institutionNames().get(user.getInstitutionId()))));
    }

    @GetMapping("/{id}/profile")
    public ResponseEntity<ApiResponse<StudentProfileResponse>> profile(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.data(profileOf(findUserUseCase.findById(id))));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<StudentProfileResponse>> setStatus(
            @PathVariable UUID id,
            @RequestBody @Valid UpdateUserStatusRequest request,
            Authentication auth) {
        User saved = manageUserStatusUseCase.setActive(id, request.active(), adminId(auth));
        return ResponseEntity.ok(ApiResponse.data(profileOf(saved)));
    }

    private StudentProfileResponse profileOf(User user) {
        List<LocalDate> attendance = listEntryRepository
                .findAttendanceSince(user.getId(), LocalDate.now().minusMonths(ATTENDANCE_MONTHS))
                .stream()
                .map(entry -> entry.getDailyList().getDate())
                .distinct()
                .toList();

        List<UserStatusLog> history = manageUserStatusUseCase.history(user.getId());
        // Um mapa só com os admins que aparecem no historico -- um findById por
        // linha viraria N+1 na primeira conta com varias mudancas.
        Map<UUID, String> adminNames = history.stream()
                .map(UserStatusLog::getAdminId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .map(userRepository::findById)
                .flatMap(java.util.Optional::stream)
                .collect(Collectors.toMap(User::getId, User::getFullName));

        List<StudentProfileResponse.StatusChange> changes = history.stream()
                .map(log -> new StudentProfileResponse.StatusChange(
                        log.getAction().name(),
                        log.getAdminId() == null ? null : adminNames.get(log.getAdminId()),
                        log.getCreatedAt()))
                .toList();

        return new StudentProfileResponse(
                user.getId(), user.getFullName(), user.getCourse(),
                institutionNames().get(user.getInstitutionId()), user.isActive(),
                attendance, changes);
    }

    private UUID adminId(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .map(User::getId)
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }

    private Map<UUID, String> institutionNames() {
        return institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));
    }
}
