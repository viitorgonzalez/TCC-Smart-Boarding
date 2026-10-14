package com.smartboarding.smartboarding_api.infrastructure.web;

import com.smartboarding.smartboarding_api.infrastructure.config.SecurityConfig;
import com.smartboarding.smartboarding_api.infrastructure.web.common.GlobalExceptionHandler;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.time.Instant;
import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

@Import({SecurityConfig.class, GlobalExceptionHandler.class})
public abstract class WebMvcTestSupport {

    @MockitoBean protected JwtDecoder jwtDecoder;

    @MockitoBean protected UserDetailsService userDetailsService;

    protected static final UUID STUDENT_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    protected static final UUID ADMIN_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

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

    protected static final String BEARER_REAL = "carimbado-antes-da-mudanca-no-banco";

    protected static Jwt tokenComScope(String email, String role) {
        Instant agora = Instant.now();
        return Jwt.withTokenValue(BEARER_REAL)
                .header("alg", "HS256")
                .subject(email)
                .claim("scope", role)
                .issuedAt(agora)
                .expiresAt(agora.plusSeconds(3600))
                .build();
    }

    protected static MockHttpServletRequestBuilder comBearerReal(MockHttpServletRequestBuilder request) {
        return request.header(HttpHeaders.AUTHORIZATION, "Bearer " + BEARER_REAL);
    }
}
