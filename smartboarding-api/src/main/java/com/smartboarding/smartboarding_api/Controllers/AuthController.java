package com.smartboarding.smartboarding_api.Controllers;


import com.smartboarding.smartboarding_api.DTO.auth.LoginRequestDTO;
import com.smartboarding.smartboarding_api.DTO.auth.LoginResponseDTO;
import com.smartboarding.smartboarding_api.DTO.auth.RegisterRequestDTO;
import com.smartboarding.smartboarding_api.DTO.auth.RegisterResponseDTO;
import com.smartboarding.smartboarding_api.Services.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController()
@RequestMapping("api/auth/")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponseDTO> login(@RequestBody @Valid LoginRequestDTO data) {
        return ResponseEntity.ok(authService.login(data));
    }

    @PostMapping("/register")
    public ResponseEntity<RegisterResponseDTO> register(@RequestBody @Valid RegisterRequestDTO data) {
        RegisterResponseDTO newUser = authService.register(data);
        return ResponseEntity.status(HttpStatus.CREATED).body(newUser);
    }
}
