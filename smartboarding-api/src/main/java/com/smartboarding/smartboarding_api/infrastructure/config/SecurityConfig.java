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
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
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
                        // RN22: quem esqueceu a senha nao esta autenticado -- por
                        // definicao, estes dois precisam ser publicos.
                        // Cadastro proprio: quem chega aqui ainda nao tem conta.
                        .requestMatchers(HttpMethod.POST, "/api/auth/signup").permitAll()
                        // Entrar com Google e caminho de entrada, como o login.
                        .requestMatchers(HttpMethod.POST, "/api/auth/google").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/forgot-password").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/reset-password").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/routes").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/routes/{id}").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/institutions").permitAll()
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
                        // O proprio perfil e do usuario logado; a fila de
                        // solicitacoes e do admin.
                        .requestMatchers(HttpMethod.GET, "/api/me").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/me/password").authenticated()
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
                        .requestMatchers(HttpMethod.PATCH, "/api/users/{id}/role").hasRole("ADMIN")
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
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter))
                );
        return http.build();
    }

    /// O papel vem do banco a cada requisicao, nao da claim "scope" do token. A
    /// claim e carimbada no login e vale 1h: tirada a autoridade da claim, um
    /// admin rebaixado seguiria admin ate o token expirar -- e nesse intervalo
    /// ele chamaria PATCH /api/users/{ele}/role e se promoveria de volta. O
    /// token continua carregando "scope", mas so como informacao.
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter(UserDetailsService userDetailsService) {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(
                jwt -> currentAuthorities(userDetailsService, jwt.getSubject()));
        return converter;
    }

    /// Conta apagada ou desativada para de autenticar, nao so de ter papel.
    /// Ficar sem autoridade nenhuma nao basta: autoridade vazia ainda satisfaz
    /// o anyRequest().authenticated(), entao o aluno desativado seguia entrando
    /// na lista do dia e pegando rota nova ate o token expirar -- justamente o
    /// abuso que desativar deveria conter. Falhando aqui, o filtro do resource
    /// server encerra em 401 antes de qualquer regra de autorizacao rodar.
    ///
    /// As mensagens sao ASCII de proposito: elas viajam no cabecalho
    /// WWW-Authenticate, e BearerTokenError recusa caractere fora do RFC 6750.
    private static Collection<GrantedAuthority> currentAuthorities(
            UserDetailsService userDetailsService, String email) {
        UserDetails user;
        try {
            user = userDetailsService.loadUserByUsername(email);
        } catch (UsernameNotFoundException e) {
            throw new InvalidBearerTokenException("Account no longer exists.");
        } catch (RuntimeException e) {
            // Banco fora atinge toda requisicao autenticada, e aqui e fora do
            // alcance do @ControllerAdvice: sem este catch cada uma delas vira
            // 500 cru. Fecha de proposito -- indisponibilidade nunca pode virar
            // permissao. Uma linha por requisicao, sem stack, senao a queda do
            // banco enterra o log que explica a queda.
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
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
