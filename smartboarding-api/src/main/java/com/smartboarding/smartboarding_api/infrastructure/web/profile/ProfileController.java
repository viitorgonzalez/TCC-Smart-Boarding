package com.smartboarding.smartboarding_api.infrastructure.web.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.profile.port.in.ManageProfileUpdateUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.SetLocalPasswordUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.SetPasswordRequest;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.profile.dto.MeResponse;
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
    private final ManageUserInstitutionsUseCase userInstitutionsUseCase;
    private final SetLocalPasswordUseCase setLocalPasswordUseCase;

    public ProfileController(ManageProfileUpdateUseCase useCase,
                             UserRepositoryPort userRepository,
                             ManageUserInstitutionsUseCase userInstitutionsUseCase,
                             SetLocalPasswordUseCase setLocalPasswordUseCase) {
        this.useCase = useCase;
        this.userRepository = userRepository;
        this.userInstitutionsUseCase = userInstitutionsUseCase;
        this.setLocalPasswordUseCase = setLocalPasswordUseCase;
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

    /// Instituições do próprio aluno. É pré-requisito pra entrar em rota, então
    /// mora aqui e não na tela de admin.
    @GetMapping("/me/institutions")
    public ResponseEntity<ApiResponse<List<UUID>>> myInstitutions(Authentication auth) {
        return ResponseEntity.ok(ApiResponse.data(
                userInstitutionsUseCase.institutionsOf(me(auth).getId())));
    }

    @PostMapping("/me/institutions/{institutionId}")
    public ResponseEntity<ApiResponse<?>> addInstitution(@PathVariable UUID institutionId,
                                                          Authentication auth) {
        userInstitutionsUseCase.add(me(auth).getId(), institutionId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success());
    }

    @DeleteMapping("/me/institutions/{institutionId}")
    public ResponseEntity<ApiResponse<?>> removeInstitution(@PathVariable UUID institutionId,
                                                             Authentication auth) {
        userInstitutionsUseCase.remove(me(auth).getId(), institutionId);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<MeResponse>> meInfo(Authentication auth) {
        return ResponseEntity.ok(ApiResponse.data(MeResponse.from(me(auth))));
    }

    /// Define a senha local de quem entrou pelo Google. A partir daí ele entra
    /// pelos dois caminhos.
    @PostMapping("/me/password")
    public ResponseEntity<ApiResponse<?>> setPassword(
            @RequestBody @Valid SetPasswordRequest body, Authentication auth) {
        setLocalPasswordUseCase.setPassword(me(auth).getId(), body.password());
        return ResponseEntity.ok(ApiResponse.success());
    }

    private User me(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
