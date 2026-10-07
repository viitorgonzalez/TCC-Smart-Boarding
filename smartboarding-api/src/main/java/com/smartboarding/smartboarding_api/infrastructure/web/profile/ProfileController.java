package com.smartboarding.smartboarding_api.infrastructure.web.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.emailchange.port.in.ConfirmEmailChangeUseCase;
import com.smartboarding.smartboarding_api.domain.emailchange.port.in.RequestEmailChangeUseCase;
import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.profile.port.in.ManageProfileUpdateUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.ChangePasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.SetLocalPasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.UpdateAddressUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.UpdateOwnProfileUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.ChangePasswordRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.AddressResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.ConfirmEmailChangeRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.RequestEmailChangeRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.SetPasswordRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UpdateAddressRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UpdateOwnProfileRequest;
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

@RestController
@RequestMapping("/api")
public class ProfileController {

    private final ManageProfileUpdateUseCase useCase;
    private final UserRepositoryPort userRepository;
    private final ManageUserInstitutionsUseCase userInstitutionsUseCase;
    private final SetLocalPasswordUseCase setLocalPasswordUseCase;
    private final ChangePasswordUseCase changePasswordUseCase;
    private final UpdateAddressUseCase updateAddressUseCase;
    private final UpdateOwnProfileUseCase updateOwnProfileUseCase;
    private final InstitutionRepositoryPort institutionRepository;
    private final RequestEmailChangeUseCase requestEmailChangeUseCase;
    private final ConfirmEmailChangeUseCase confirmEmailChangeUseCase;

    public ProfileController(ManageProfileUpdateUseCase useCase,
                             UserRepositoryPort userRepository,
                             ManageUserInstitutionsUseCase userInstitutionsUseCase,
                             SetLocalPasswordUseCase setLocalPasswordUseCase,
                             ChangePasswordUseCase changePasswordUseCase,
                             UpdateAddressUseCase updateAddressUseCase,
                             UpdateOwnProfileUseCase updateOwnProfileUseCase,
                             InstitutionRepositoryPort institutionRepository,
                             RequestEmailChangeUseCase requestEmailChangeUseCase,
                             ConfirmEmailChangeUseCase confirmEmailChangeUseCase) {
        this.useCase = useCase;
        this.userRepository = userRepository;
        this.userInstitutionsUseCase = userInstitutionsUseCase;
        this.setLocalPasswordUseCase = setLocalPasswordUseCase;
        this.changePasswordUseCase = changePasswordUseCase;
        this.updateAddressUseCase = updateAddressUseCase;
        this.updateOwnProfileUseCase = updateOwnProfileUseCase;
        this.institutionRepository = institutionRepository;
        this.requestEmailChangeUseCase = requestEmailChangeUseCase;
        this.confirmEmailChangeUseCase = confirmEmailChangeUseCase;
    }

    @PostMapping("/me/profile-requests")
    public ResponseEntity<ApiResponse<ProfileUpdateResponse>> request(
            @RequestBody @Valid ProfileUpdateRequestDto body, Authentication auth) {
        User me = me(auth);
        var saved = useCase.request(me.getId(), ProfileUpdateRequest.builder()
                .fullName(body.fullName())
                .institutionId(body.institutionId())
                .birthDate(body.birthDate())
                .phone(body.phone())
                .course(body.course())
                .structuredAddress(body.addressOrNull())
                .build());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(ProfileUpdateResponse.from(saved, me)));
    }

    @GetMapping("/me/profile-requests/pending")
    public ResponseEntity<ApiResponse<ProfileUpdateResponse>> myPending(Authentication auth) {
        User me = me(auth);
        return ResponseEntity.ok(ApiResponse.data(useCase.myPending(me.getId())
                .map(r -> ProfileUpdateResponse.from(r, me))
                .orElse(null)));
    }

    @GetMapping("/profile-requests")
    public ResponseEntity<ApiResponse<List<ProfileUpdateResponse>>> pending() {
        var pedidos = useCase.listPending();
        Map<UUID, User> usuarios = userRepository.findAll().stream()
                .collect(Collectors.toMap(User::getId, u -> u));
        return ResponseEntity.ok(ApiResponse.data(pedidos.stream()
                .map(r -> ProfileUpdateResponse.from(r, usuarios.get(r.getUserId())))
                .toList()));
    }

    @GetMapping("/profile-requests/all")
    public ResponseEntity<ApiResponse<List<ProfileUpdateResponse>>> all(
            @RequestParam(required = false) String status) {
        var pedidos = useCase.listAll(status);
        Map<UUID, User> usuarios = userRepository.findAll().stream()
                .collect(Collectors.toMap(User::getId, u -> u));
        return ResponseEntity.ok(ApiResponse.data(pedidos.stream()
                .map(r -> ProfileUpdateResponse.from(r, usuarios.get(r.getUserId())))
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

    @GetMapping("/me/profile-requests/latest")
    public ResponseEntity<ApiResponse<ProfileUpdateResponse>> myLatest(Authentication auth) {
        User me = me(auth);
        return ResponseEntity.ok(ApiResponse.data(useCase.myLatest(me.getId())
                .map(r -> ProfileUpdateResponse.from(r, me)).orElse(null)));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<MeResponse>> meInfo(Authentication auth) {
        return ResponseEntity.ok(ApiResponse.data(comInstituicao(me(auth))));
    }

    private MeResponse comInstituicao(User user) {
        String nome = user.getInstitutionId() == null ? null
                : institutionRepository.findById(user.getInstitutionId())
                        .map(Institution::getName).orElse(null);
        return MeResponse.from(user, nome);
    }

    @PostMapping("/me/password")
    public ResponseEntity<ApiResponse<?>> setPassword(
            @RequestBody @Valid SetPasswordRequest body, Authentication auth) {
        setLocalPasswordUseCase.setPassword(me(auth).getId(), body.password());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PutMapping("/me/password")
    public ResponseEntity<ApiResponse<?>> changePassword(
            @RequestBody @Valid ChangePasswordRequest body, Authentication auth) {
        changePasswordUseCase.changePassword(
                me(auth).getId(), body.currentPassword(), body.newPassword());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/me/email/request")
    public ResponseEntity<ApiResponse<?>> requestEmailChange(
            @RequestBody @Valid RequestEmailChangeRequest body, Authentication auth) {
        requestEmailChangeUseCase.request(me(auth).getId(), body.newEmail());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/me/email/confirm")
    public ResponseEntity<ApiResponse<?>> confirmEmailChange(
            @RequestBody @Valid ConfirmEmailChangeRequest body, Authentication auth) {
        confirmEmailChangeUseCase.confirm(me(auth).getId(), body.code());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PutMapping("/me/address")
    public ResponseEntity<ApiResponse<AddressResponse>> updateAddress(
            @RequestBody @Valid UpdateAddressRequest body, Authentication auth) {
        var salvo = updateAddressUseCase.update(me(auth).getId(), body.toDomain());
        return ResponseEntity.ok(ApiResponse.data(AddressResponse.from(salvo)));
    }

    @PutMapping("/me/profile")
    public ResponseEntity<ApiResponse<MeResponse>> updateOwnProfile(
            @RequestBody @Valid UpdateOwnProfileRequest body, Authentication auth) {
        User me = me(auth);
        updateOwnProfileUseCase.update(me.getId(), body.phone(), body.course());
        return ResponseEntity.ok(ApiResponse.data(comInstituicao(me(auth))));
    }

    private User me(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
