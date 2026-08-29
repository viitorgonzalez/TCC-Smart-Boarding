package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ApproveRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ListPendingRegistrationsUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.RejectRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ResendCodeUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ValidateTokenUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.VerifyInviteCodeUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.InviteInfoResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.InviteRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.PendingRegistrationResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.RejectRegistrationRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.ResendCodeRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.SubmitRegistrationRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.VerifyInviteCodeRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.VerifyInviteCodeResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/registration")
public class RegistrationController {

    private final GenerateInviteUseCase generateInviteUseCase;
    private final ValidateTokenUseCase validateTokenUseCase;
    private final SubmitRegistrationUseCase submitRegistrationUseCase;
    private final ListPendingRegistrationsUseCase listPendingRegistrationsUseCase;
    private final ApproveRegistrationUseCase approveRegistrationUseCase;
    private final RejectRegistrationUseCase rejectRegistrationUseCase;
    private final VerifyInviteCodeUseCase verifyInviteCodeUseCase;
    private final ResendCodeUseCase resendCodeUseCase;
    private final InstitutionRepositoryPort institutionRepository;

    public RegistrationController(GenerateInviteUseCase generateInviteUseCase,
                                   ValidateTokenUseCase validateTokenUseCase,
                                   SubmitRegistrationUseCase submitRegistrationUseCase,
                                   ListPendingRegistrationsUseCase listPendingRegistrationsUseCase,
                                   ApproveRegistrationUseCase approveRegistrationUseCase,
                                   RejectRegistrationUseCase rejectRegistrationUseCase,
                                   VerifyInviteCodeUseCase verifyInviteCodeUseCase,
                                   ResendCodeUseCase resendCodeUseCase,
                                   InstitutionRepositoryPort institutionRepository) {
        this.generateInviteUseCase = generateInviteUseCase;
        this.validateTokenUseCase = validateTokenUseCase;
        this.submitRegistrationUseCase = submitRegistrationUseCase;
        this.listPendingRegistrationsUseCase = listPendingRegistrationsUseCase;
        this.approveRegistrationUseCase = approveRegistrationUseCase;
        this.rejectRegistrationUseCase = rejectRegistrationUseCase;
        this.verifyInviteCodeUseCase = verifyInviteCodeUseCase;
        this.resendCodeUseCase = resendCodeUseCase;
        this.institutionRepository = institutionRepository;
    }

    @PostMapping("/invite")
    public ResponseEntity<ApiResponse<?>> invite(@RequestBody @Valid InviteRequest request) {
        generateInviteUseCase.generateInvite(request.email());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success());
    }

    @PostMapping("/resend-code")
    public ResponseEntity<ApiResponse<?>> resendCode(@RequestBody @Valid ResendCodeRequest request) {
        resendCodeUseCase.resendCode(request.email());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/verify-code")
    public ResponseEntity<ApiResponse<VerifyInviteCodeResponse>> verifyCode(@RequestBody @Valid VerifyInviteCodeRequest request) {
        String token = verifyInviteCodeUseCase.verifyCode(request.email(), request.code());
        return ResponseEntity.ok(ApiResponse.data(new VerifyInviteCodeResponse(token)));
    }

    @GetMapping("/invite/{token}")
    public ResponseEntity<ApiResponse<InviteInfoResponse>> getInvite(@PathVariable String token) {
        var request = validateTokenUseCase.validateToken(token);
        return ResponseEntity.ok(ApiResponse.data(InviteInfoResponse.from(request)));
    }

    @PostMapping("/{token}/submit")
    public ResponseEntity<ApiResponse<?>> submit(@PathVariable String token,
                                                  @RequestBody @Valid SubmitRegistrationRequest request) {
        submitRegistrationUseCase.submitRegistration(token, new SubmitRegistrationUseCase.SubmitData(
                request.fullName(), request.password(), request.institutionId(),
                request.course(), request.phone(), request.address(), request.birthDate()));
        return ResponseEntity.ok(ApiResponse.data(java.util.Map.of("status", "SUBMITTED")));
    }

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<PendingRegistrationResponse>>> pending() {
        // Lista pequena e admin-facing: busca todas as instituições de uma vez em vez de
        // um findById por linha (N+1 seria aceitável aqui, mas isso é mais barato ainda).
        Map<UUID, String> institutionNamesById = institutionRepository.findAll().stream()
                .collect(Collectors.toMap(Institution::getId, Institution::getName));

        var result = listPendingRegistrationsUseCase.listPending().stream()
                .map(request -> PendingRegistrationResponse.from(request,
                        institutionNamesById.get(request.getInstitutionId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(result));
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<?>> approve(@PathVariable UUID id) {
        approveRegistrationUseCase.approve(id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<?>> reject(@PathVariable UUID id,
                                                 @RequestBody @Valid RejectRegistrationRequest request) {
        rejectRegistrationUseCase.reject(id, request.reason());
        return ResponseEntity.ok(ApiResponse.success());
    }
}
