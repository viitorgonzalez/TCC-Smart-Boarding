package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.application.user.AuthToken;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.LoginUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.RequestPasswordResetUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.ResetPasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.GoogleSignInUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.IssueTokenUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.SignupUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.ForgotPasswordRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.LoginRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.LoginResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.GoogleSignInRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.SignupRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.ResetPasswordRequest;
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
    private final RequestPasswordResetUseCase requestPasswordResetUseCase;
    private final ResetPasswordUseCase resetPasswordUseCase;
    private final SignupUseCase signupUseCase;
    private final GoogleSignInUseCase googleSignInUseCase;
    private final IssueTokenUseCase issueTokenUseCase;

    public AuthController(LoginUseCase loginUseCase,
                          RequestPasswordResetUseCase requestPasswordResetUseCase,
                          ResetPasswordUseCase resetPasswordUseCase,
                          SignupUseCase signupUseCase,
                          GoogleSignInUseCase googleSignInUseCase,
                          IssueTokenUseCase issueTokenUseCase) {
        this.loginUseCase = loginUseCase;
        this.requestPasswordResetUseCase = requestPasswordResetUseCase;
        this.resetPasswordUseCase = resetPasswordUseCase;
        this.signupUseCase = signupUseCase;
        this.googleSignInUseCase = googleSignInUseCase;
        this.issueTokenUseCase = issueTokenUseCase;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@RequestBody @Valid LoginRequest request) {
        AuthToken token = loginUseCase.execute(request.email(), request.password());
        return ResponseEntity.ok(ApiResponse.data(LoginResponse.from(token)));
    }

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<LoginResponse>> signup(@RequestBody @Valid SignupRequest request) {
        User created = signupUseCase.signup(User.builder()
                .email(request.email())
                .fullName(request.fullName())
                .build(), request.password());

        AuthToken token = loginUseCase.execute(created.getEmail(), request.password());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(
                LoginResponse.from(token)));
    }

    @PostMapping("/google")
    public ResponseEntity<ApiResponse<LoginResponse>> google(
            @RequestBody @Valid GoogleSignInRequest request) {
        User user = googleSignInUseCase.signIn(request.idToken());
        AuthToken token = issueTokenUseCase.issueFor(user);
        return ResponseEntity.ok(ApiResponse.data(
                LoginResponse.from(token)));
    }

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
