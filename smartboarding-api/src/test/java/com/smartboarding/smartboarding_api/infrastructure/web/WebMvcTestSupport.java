package com.smartboarding.smartboarding_api.infrastructure.web;

import com.smartboarding.smartboarding_api.infrastructure.config.SecurityConfig;
import com.smartboarding.smartboarding_api.infrastructure.web.common.GlobalExceptionHandler;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

/// Base dos testes de controller. Importa o SecurityConfig de produção de
/// propósito: um teste com a segurança desligada passaria mesmo se a regra de
/// autorização do endpoint estivesse errada, que é justamente o que precisa de
/// rede aqui.
@Import({SecurityConfig.class, GlobalExceptionHandler.class})
public abstract class WebMvcTestSupport {

    /// O decoder de verdade lê a chave da config; nos testes a autenticação vem
    /// pronta pelos post-processors, então ele nunca é chamado.
    @MockitoBean protected JwtDecoder jwtDecoder;

    protected static final UUID STUDENT_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    protected static final UUID ADMIN_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    /// Espelha o token de produção: papel no claim "scope", prefixo ROLE_ posto
    /// pelo JwtGrantedAuthoritiesConverter.
    private static RequestPostProcessor as(UUID id, String email, String role) {
        return jwt()
                .jwt(builder -> builder.subject(email).claim("scope", role).claim("uid", id.toString()))
                .authorities(new SimpleGrantedAuthority("ROLE_" + role));
    }

    protected static RequestPostProcessor student() {
        return as(STUDENT_ID, "fernanda@edu.unifor.br", "STUDENT");
    }

    protected static RequestPostProcessor admin() {
        return as(ADMIN_ID, "naiara@admin.com", "ADMIN");
    }
}
