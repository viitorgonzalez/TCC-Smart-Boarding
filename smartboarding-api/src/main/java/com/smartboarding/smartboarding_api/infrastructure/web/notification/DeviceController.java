package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.domain.notification.port.in.RegisterDeviceTokenUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.RemoveDeviceTokenUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.notification.dto.DeviceTokenRequest;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/devices")
public class DeviceController {

    private final RegisterDeviceTokenUseCase registerDeviceTokenUseCase;
    private final RemoveDeviceTokenUseCase removeDeviceTokenUseCase;
    private final UserRepositoryPort userRepository;

    public DeviceController(RegisterDeviceTokenUseCase registerDeviceTokenUseCase,
                            RemoveDeviceTokenUseCase removeDeviceTokenUseCase,
                            UserRepositoryPort userRepository) {
        this.registerDeviceTokenUseCase = registerDeviceTokenUseCase;
        this.removeDeviceTokenUseCase = removeDeviceTokenUseCase;
        this.userRepository = userRepository;
    }

    @PostMapping("/token")
    public ResponseEntity<ApiResponse<?>> register(@RequestBody @Valid DeviceTokenRequest request,
                                                   Authentication auth) {
        UUID userId = resolveUserId(auth);
        registerDeviceTokenUseCase.execute(userId, request.token(), request.platform());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @DeleteMapping("/token")
    public ResponseEntity<ApiResponse<?>> remove(Authentication auth) {
        UUID userId = resolveUserId(auth);
        removeDeviceTokenUseCase.execute(userId);
        return ResponseEntity.ok(ApiResponse.success());
    }

    private UUID resolveUserId(Authentication auth) {
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }
}
