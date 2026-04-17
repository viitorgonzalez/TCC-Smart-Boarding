package com.smartboarding.smartboarding_api.Services;

import com.smartboarding.smartboarding_api.DTO.auth.LoginRequestDTO;
import com.smartboarding.smartboarding_api.DTO.auth.LoginResponseDTO;
import com.smartboarding.smartboarding_api.DTO.auth.RegisterRequestDTO;
import com.smartboarding.smartboarding_api.DTO.auth.RegisterResponseDTO;
import com.smartboarding.smartboarding_api.Models.User;
import com.smartboarding.smartboarding_api.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService ;

    public RegisterResponseDTO register(RegisterRequestDTO data) {
        if (userRepository.findByEmail(data.email()).isPresent()) {
            throw new RuntimeException("User already registered with this email.");
        }

        User newUser = User.builder()
                .email(data.email())
                .password(passwordEncoder.encode(data.password()))
                .role(data.role())
                .fullName(data.fullName())
                .isActive(true)
                .build();

        User savedUser = userRepository.save(newUser);

        return new RegisterResponseDTO(savedUser.getId(), savedUser.getEmail());
    }

    public LoginResponseDTO login(LoginRequestDTO data) {
        var user = userRepository.findByEmail(data.email())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(data.password(), user.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        Authentication auth = new UsernamePasswordAuthenticationToken(
                user.getEmail(),
                null,
                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );

        return tokenService.generateLoginResponse(auth, user.getFullName(), user.getRole().name());
    }
}
