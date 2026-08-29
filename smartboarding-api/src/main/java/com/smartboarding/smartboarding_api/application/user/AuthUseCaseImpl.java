package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.LoginUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.RegisterUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.stream.Collectors;

@Slf4j
@Service
public class AuthUseCaseImpl implements LoginUseCase, RegisterUseCase, UserDetailsService {

    private static final long EXPIRY_SECONDS = 3600L;
    private static final String ISSUER = "smartboarding-api";

    private final UserRepositoryPort userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;

    public AuthUseCaseImpl(UserRepositoryPort userRepository,
                           PasswordEncoder passwordEncoder,
                           JwtEncoder jwtEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
    }

    @Override
    public AuthToken execute(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UnauthorizedException("Credenciais inválidas"));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new UnauthorizedException("Credenciais inválidas");
        }

        String token = generateToken(user);
        log.info("Login realizado: {}", maskEmail(email));
        return new AuthToken(token, user.getFullName(), user.getRole().name());
    }

    @Override
    @Transactional
    public User execute(User user, String rawPassword) {
        // Aluno nasce exclusivamente por convite (RN13) — este endpoint existe só
        // pra um admin criar outro admin. Sem a trava, a criação manual burlaria
        // todo o fluxo de aprovação.
        if (user.getRole() != Role.ADMIN) {
            throw new BadRequestException("ADMIN_ONLY",
                    "Só é possível criar conta de administrador aqui; aluno entra por convite");
        }

        if (userRepository.existsByEmail(user.getEmail())) {
            throw new ConflictException("EMAIL_ALREADY_EXISTS", "E-mail já cadastrado: " + user.getEmail());
        }

        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setActive(true);

        User saved = userRepository.save(user);
        log.info("Usuário registrado: {}", maskEmail(saved.getEmail()));
        return saved;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Usuário não encontrado: " + email));
    }

    private String generateToken(User user) {
        Instant now = Instant.now();
        String scope = user.getAuthorities().stream()
                .map(a -> a.getAuthority().replace("ROLE_", ""))
                .collect(Collectors.joining(" "));

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(ISSUER)
                .issuedAt(now)
                .expiresAt(now.plusSeconds(EXPIRY_SECONDS))
                .subject(user.getEmail())
                .claim("scope", scope)
                .build();

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return "***";
        return email.charAt(0) + "***" + email.substring(email.indexOf('@'));
    }
}
