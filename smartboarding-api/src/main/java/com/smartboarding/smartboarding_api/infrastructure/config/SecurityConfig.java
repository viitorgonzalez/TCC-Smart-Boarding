package com.smartboarding.smartboarding_api.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()
                        // RN22: quem esqueceu a senha nao esta autenticado -- por
                        // definicao, estes dois precisam ser publicos.
                        // Cadastro proprio: quem chega aqui ainda nao tem conta.
                        .requestMatchers(HttpMethod.POST, "/api/auth/signup").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/forgot-password").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/reset-password").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/routes").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/routes/{id}").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/institutions").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/registration/invite/{token}").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/registration/{token}/submit").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/registration/verify-code").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/registration/resend-code").permitAll()
                        .requestMatchers(HttpMethod.GET, "/register/{token}").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/register").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/users/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/routes").hasRole("ADMIN")
                        // Sub-recursos de rota: sem regra explícita, POST em
                        // /api/routes/{id}/stops cairia no anyRequest().authenticated()
                        // e qualquer aluno poderia criar parada.
                        .requestMatchers(HttpMethod.POST, "/api/routes/*/stops").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/routes/*/stops/**").hasRole("ADMIN")
                        // Gerar, listar e revogar codigo e do admin. Sem estas
                        // linhas o caminho cairia no anyRequest().authenticated()
                        // e um aluno emitiria codigo pra propria rota.
                        .requestMatchers("/api/routes/*/invite-codes/**").hasRole("ADMIN")
                        .requestMatchers("/api/routes/*/invite-codes").hasRole("ADMIN")
                        // Usar o codigo e do aluno logado, sobre as rotas DELE.
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
                        .requestMatchers(HttpMethod.POST, "/api/registration/invite").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/registration/pending").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/registration/{id}/approve").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/registration/{id}/reject").hasRole("ADMIN")
                        // Ver quem está na lista: qualquer usuário autenticado (aluno inclusive)
                        .requestMatchers(HttpMethod.GET, "/api/lists/{id}/entries").authenticated()
                        // Gestão de listas é do admin. Padrões exatos: entrar e
                        // sair da lista são /api/lists/{id}/entries e não podem
                        // cair nestas regras.
                        // Inclusão/remoção tardia é do admin: fura o horário de propósito.
                        .requestMatchers(HttpMethod.POST, "/api/lists/{id}/entries/admin").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/lists/{id}/entries/{userId}").hasRole("ADMIN")
                        // O aluno vê só as próprias advertências (/me); o resto é do admin.
                        .requestMatchers(HttpMethod.GET, "/api/warnings/me").authenticated()
                        .requestMatchers("/api/warnings/**").hasRole("ADMIN")
                        // RN23: conduzir trajeto e acao de admin, nao de aluno.
                        .requestMatchers("/api/trip/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/users/{id}/profile").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/users/{id}/status").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/lists").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/lists").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/lists/{id}").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/lists/{id}").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.GET, "/api/reports/**").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/notifications/**").hasRole("ADMIN")
                        // Caixa de entrada do aluno: o filtro por rota/validade
                        // é feito no use case, por isso basta estar autenticado.
                        .requestMatchers(HttpMethod.GET, "/api/notifications").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/notifications").hasRole("ADMIN")
                        .requestMatchers("/api/notifications/scheduled/**").hasRole("ADMIN")
                        .requestMatchers("/api/notifications/scheduled").hasRole("ADMIN")
                        .anyRequest().authenticated()
                ).oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
                );
        return http.build();
    }

    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();
        grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");
        grantedAuthoritiesConverter.setAuthoritiesClaimName("scope");

        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
        return jwtAuthenticationConverter;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
