package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.application.user.AuthToken;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.LoginUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.RequestPasswordResetUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.ResetPasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.RegisterUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.ForgotPasswordRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.LoginRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.LoginResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.RegisterRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.ResetPasswordRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UserResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final LoginUseCase loginUseCase;
    private final RegisterUseCase registerUseCase;
    private final RequestPasswordResetUseCase requestPasswordResetUseCase;
    private final ResetPasswordUseCase resetPasswordUseCase;

    public AuthController(LoginUseCase loginUseCase,
                          RegisterUseCase registerUseCase,
                          RequestPasswordResetUseCase requestPasswordResetUseCase,
                          ResetPasswordUseCase resetPasswordUseCase) {
        this.loginUseCase = loginUseCase;
        this.registerUseCase = registerUseCase;
        this.requestPasswordResetUseCase = requestPasswordResetUseCase;
        this.resetPasswordUseCase = resetPasswordUseCase;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@RequestBody @Valid LoginRequest request) {
        AuthToken token = loginUseCase.execute(request.email(), request.password());
        return ResponseEntity.ok(ApiResponse.data(new LoginResponse(token.token(), token.fullName(), token.role())));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<UserResponse>> register(@RequestBody @Valid RegisterRequest request) {
        User user = User.builder()
                .email(request.email())
                .fullName(request.fullName())
                .role(request.role())
                .build();
        User saved = registerUseCase.execute(user, request.password());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(UserResponse.from(saved, null)));
    }

    /// Responde igual havendo conta ou não (RN22) -- por isso não devolve dado nenhum.
    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<?>> forgotPassword(@RequestBody @Valid ForgotPasswordRequest request) {
        requestPasswordResetUseCase.request(request.email());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<?>> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
        resetPasswordUseCase.reset(request.email(), request.code(), request.newPassword());
        return ResponseEntity.ok(ApiResponse.success());
    }
}
