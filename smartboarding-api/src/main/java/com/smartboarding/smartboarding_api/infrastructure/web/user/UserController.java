package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.domain.user.port.in.FindUserUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UserResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final FindUserUseCase findUserUseCase;

    public UserController(FindUserUseCase findUserUseCase) {
        this.findUserUseCase = findUserUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponse>>> listAll() {
        List<UserResponse> users = findUserUseCase.findAll().stream()
                .map(UserResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(users));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> findById(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.data(UserResponse.from(findUserUseCase.findById(id))));
    }
}
