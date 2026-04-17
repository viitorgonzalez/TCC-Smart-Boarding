package com.smartboarding.smartboarding_api.Services;

import com.smartboarding.smartboarding_api.DTO.auth.LoginResponseDTO;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class TokenService {

    private final JwtEncoder jwtEncoder;
    public static final long EXPIRY_SECONDS = 3600L;
    private static final String ISSUER = "smartboarding-api";

    public TokenService(JwtEncoder jwtEncoder) {
        this.jwtEncoder = jwtEncoder;
    }

    public LoginResponseDTO generateLoginResponse(Authentication auth, String fullName, String role) {
        String token = generateToken(auth);
        return new LoginResponseDTO(token, fullName, role);
    }

    public String generateToken(Authentication authentication) {
        Instant now = Instant.now();
        String scope = extractScopes(authentication);

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(ISSUER)
                .issuedAt(now)
                .expiresAt(now.plusSeconds(EXPIRY_SECONDS))
                .subject(authentication.getName())
                .claim("scope", scope)
                .build();

        JwsHeader jwsHeader = JwsHeader.with(MacAlgorithm.HS256).build();
        JwtEncoderParameters parameters = JwtEncoderParameters.from(jwsHeader, claims);

        try {
            return jwtEncoder.encode(parameters).getTokenValue();
        } catch (JwtEncodingException e) {
            throw new RuntimeException("Error generating JWT token", e);
        }
    }

    private String extractScopes(Authentication auth) {
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(Objects::nonNull)
                // Standardizing: OAuth2 resources usually expect scopes without the ROLE_ prefix
                .map(role -> role.replace("ROLE_", ""))
                .collect(Collectors.joining(" "));
    }
}
