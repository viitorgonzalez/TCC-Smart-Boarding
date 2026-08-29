package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.FindUserUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UserResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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

    public UserController(FindUserUseCase findUserUseCase,
                          InstitutionRepositoryPort institutionRepository) {
        this.findUserUseCase = findUserUseCase;
        this.institutionRepository = institutionRepository;
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

    private Map<UUID, String> institutionNames() {
        return institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));
    }
}
