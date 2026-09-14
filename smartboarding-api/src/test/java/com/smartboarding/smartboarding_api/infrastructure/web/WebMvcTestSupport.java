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

/// Base dos testes de controller. Importa o SecurityConfig de produção de
/// propósito: um teste com a segurança desligada passaria mesmo se a regra de
/// autorização do endpoint estivesse errada, que é justamente o que precisa de
/// rede aqui.
@Import({SecurityConfig.class, GlobalExceptionHandler.class})
public abstract class WebMvcTestSupport {

    /// O decoder de verdade lê a chave da config; nos testes a autenticação vem
    /// pronta pelos post-processors, então ele nunca é chamado — exceto nos
    /// testes que mandam um Bearer de verdade pra exercitar o converter.
    @MockitoBean protected JwtDecoder jwtDecoder;

    /// O SecurityConfig resolve as authorities consultando o usuário a cada
    /// requisição; o bean real é da camada de aplicação e não entra na fatia
    /// @WebMvcTest. Os post-processors abaixo não passam pelo converter, então
    /// só os testes que mandam Bearer de verdade precisam stubar este mock.
    @MockitoBean protected UserDetailsService userDetailsService;

    protected static final UUID STUDENT_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    protected static final UUID ADMIN_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    /// Autenticação pronta, posta direto no contexto: o post-processor não passa
    /// pelo filtro de resource server, então as authorities vêm daqui e não do
    /// converter. Pra testar o converter (papel vindo do banco), mande um
    /// header Authorization de verdade e stube jwtDecoder + userDetailsService.
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

    /// Um Bearer de verdade: o único caminho que atravessa o converter do
    /// SecurityConfig e, por consequência, a checagem de conta viva no banco.
    /// Quem usa precisa stubar `jwtDecoder` e `userDetailsService`.
    protected static final String BEARER_REAL = "carimbado-antes-da-mudanca-no-banco";

    /// O "scope" carimbado no login é informação, não autoridade: o teste manda
    /// o papel mais alto de propósito pra provar que o banco é quem decide.
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
