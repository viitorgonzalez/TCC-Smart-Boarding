package com.smartboarding.smartboarding_api.infrastructure.web.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.port.in.ManageProfileUpdateUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.profile.dto.ProfileUpdateRequestDto;
import com.smartboarding.smartboarding_api.infrastructure.web.profile.dto.ProfileUpdateResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.profile.dto.RejectProfileUpdateRequest;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/// Perfil do próprio usuário e a fila de solicitações.
///
/// O id sempre sai do token: aceitar userId do request deixaria um aluno pedir
/// alteração no perfil de outro.
@RestController
@RequestMapping("/api")
public class ProfileController {

    private final ManageProfileUpdateUseCase useCase;
    private final UserRepositoryPort userRepository;

    public ProfileController(ManageProfileUpdateUseCase useCase,
                             UserRepositoryPort userRepository) {
        this.useCase = useCase;
        this.userRepository = userRepository;
    }

    @PostMapping("/me/profile-requests")
    public ResponseEntity<ApiResponse<ProfileUpdateResponse>> request(
            @RequestBody @Valid ProfileUpdateRequestDto body, Authentication auth) {
        User me = me(auth);
        var saved = useCase.request(me.getId(), ProfileUpdateRequest.builder()
                .fullName(body.fullName()).phone(body.phone()).address(body.address())
                .course(body.course()).institutionId(body.institutionId())
                .birthDate(body.birthDate()).build());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(ProfileUpdateResponse.from(saved, me.getFullName())));
    }

    /// Pendente do próprio aluno — a tela mostra "em análise" em vez de deixar
    /// ele reenviar e tomar 409.
    @GetMapping("/me/profile-requests/pending")
    public ResponseEntity<ApiResponse<ProfileUpdateResponse>> myPending(Authentication auth) {
        User me = me(auth);
        return ResponseEntity.ok(ApiResponse.data(useCase.myPending(me.getId())
                .map(r -> ProfileUpdateResponse.from(r, me.getFullName()))
                .orElse(null)));
    }

    @GetMapping("/profile-requests")
    public ResponseEntity<ApiResponse<List<ProfileUpdateResponse>>> pending() {
        var pedidos = useCase.listPending();
        // Um mapa so com os alunos da fila -- um findById por linha viraria N+1.
        Map<UUID, String> nomes = userRepository.findAll().stream()
                .collect(Collectors.toMap(User::getId, User::getFullName));
        return ResponseEntity.ok(ApiResponse.data(pedidos.stream()
                .map(r -> ProfileUpdateResponse.from(r, nomes.get(r.getUserId())))
                .toList()));
    }

    @PostMapping("/profile-requests/{id}/approve")
    public ResponseEntity<ApiResponse<?>> approve(@PathVariable UUID id, Authentication auth) {
        useCase.approve(id, me(auth).getId());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/profile-requests/{id}/reject")
    public ResponseEntity<ApiResponse<?>> reject(@PathVariable UUID id,
                                                  @RequestBody @Valid RejectProfileUpdateRequest body,
                                                  Authentication auth) {
        useCase.reject(id, body.reason(), me(auth).getId());
        return ResponseEntity.ok(ApiResponse.success());
    }

    private User me(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
