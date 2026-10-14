package com.smartboarding.smartboarding_api.infrastructure.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import com.smartboarding.smartboarding_api.infrastructure.auth.PepperedPasswordEncoder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2ErrorCodes;
import org.springframework.security.oauth2.server.resource.BearerTokenError;
import org.springframework.security.oauth2.server.resource.InvalidBearerTokenException;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Collection;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@Slf4j
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http, JwtAuthenticationConverter jwtAuthenticationConverter) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/signup").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/google").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/forgot-password").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/reset-password").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/routes").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/routes/{id}").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/institutions").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/users/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/routes").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/routes/*/stops").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/routes/*/stops/**").hasRole("ADMIN")
                        .requestMatchers("/api/routes/*/invite-codes/**").hasRole("ADMIN")
                        .requestMatchers("/api/routes/*/invite-codes").hasRole("ADMIN")
                        .requestMatchers("/api/invite-codes").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/invite-codes").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/me").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/me/password").authenticated()
                        .requestMatchers(HttpMethod.PUT, "/api/me/password").authenticated()
                        .requestMatchers("/api/me/institutions/**").authenticated()
                        .requestMatchers("/api/me/institutions").authenticated()
                        .requestMatchers("/api/me/profile-requests/**").authenticated()
                        .requestMatchers("/api/me/profile-requests").authenticated()
                        .requestMatchers("/api/profile-requests/**").hasRole("ADMIN")
                        .requestMatchers("/api/profile-requests").hasRole("ADMIN")
                        .requestMatchers("/api/me/routes/**").authenticated()
                        .requestMatchers("/api/me/routes").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/routes/*/vehicles").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/routes/*/vehicles").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/routes/*/stops/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/routes/*/vehicles/**").hasRole("ADMIN")
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/routes/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/routes/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/institutions").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/institutions/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/institutions/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/lists/{id}/entries").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/lists/{id}/entries/admin").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/lists/{id}/entries/{userId}").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/warnings/me").authenticated()
                        .requestMatchers("/api/warnings/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/trip/{listId}").authenticated()
                        .requestMatchers("/api/trip/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/users/{id}/profile").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/users/{id}/status").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/users/{id}/role").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/lists").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/lists").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/lists/{id}").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/lists/{id}").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/reports/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/notifications/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/notifications").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/notifications").hasRole("ADMIN")
                        .requestMatchers("/api/notifications/scheduled/**").hasRole("ADMIN")
                        .requestMatchers("/api/notifications/scheduled").hasRole("ADMIN")
                        .anyRequest().authenticated()
                ).oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter))
                );
        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter(UserDetailsService userDetailsService) {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(
                jwt -> currentAuthorities(userDetailsService, jwt.getSubject()));
        return converter;
    }

    private static Collection<GrantedAuthority> currentAuthorities(
            UserDetailsService userDetailsService, String email) {
        UserDetails user;
        try {
            user = userDetailsService.loadUserByUsername(email);
        } catch (UsernameNotFoundException e) {
            throw new InvalidBearerTokenException("Account no longer exists.");
        } catch (RuntimeException e) {
            log.error("Nao foi possivel carregar o usuario do token: {}", e.toString());
            throw new OAuth2AuthenticationException(new BearerTokenError(
                    OAuth2ErrorCodes.SERVER_ERROR, HttpStatus.SERVICE_UNAVAILABLE,
                    "Cannot verify the access token right now.", null));
        }
        if (!user.isEnabled()) {
            throw new InvalidBearerTokenException("Account is not active.");
        }
        return List.copyOf(user.getAuthorities());
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder(
            @Value("${app.security.password-pepper}") String pepper) {
        return new PepperedPasswordEncoder(pepper);
    }
}
