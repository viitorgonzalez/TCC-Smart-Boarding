package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.InviteRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/registration")
public class RegistrationController {

    private final GenerateInviteUseCase generateInviteUseCase;

    public RegistrationController(GenerateInviteUseCase generateInviteUseCase) {
        this.generateInviteUseCase = generateInviteUseCase;
    }

    @PostMapping("/invite")
    public ResponseEntity<ApiResponse<?>> invite(@RequestBody @Valid InviteRequest request) {
        generateInviteUseCase.generateInvite(request.email());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success());
    }
}
