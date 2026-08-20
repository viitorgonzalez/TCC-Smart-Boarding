package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ValidateTokenUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.InviteInfoResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.InviteRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.SubmitRegistrationRequest;
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

@RestController
@RequestMapping("/api/registration")
public class RegistrationController {

    private final GenerateInviteUseCase generateInviteUseCase;
    private final ValidateTokenUseCase validateTokenUseCase;
    private final SubmitRegistrationUseCase submitRegistrationUseCase;

    public RegistrationController(GenerateInviteUseCase generateInviteUseCase,
                                   ValidateTokenUseCase validateTokenUseCase,
                                   SubmitRegistrationUseCase submitRegistrationUseCase) {
        this.generateInviteUseCase = generateInviteUseCase;
        this.validateTokenUseCase = validateTokenUseCase;
        this.submitRegistrationUseCase = submitRegistrationUseCase;
    }

    @PostMapping("/invite")
    public ResponseEntity<ApiResponse<?>> invite(@RequestBody @Valid InviteRequest request) {
        generateInviteUseCase.generateInvite(request.email());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success());
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
}
