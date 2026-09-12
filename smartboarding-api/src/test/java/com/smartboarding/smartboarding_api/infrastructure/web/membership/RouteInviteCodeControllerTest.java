package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RouteInviteCodeController.class)
@Import(RouteInviteCodeControllerTest.FixedClock.class)
class RouteInviteCodeControllerTest extends WebMvcTestSupport {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 11, 10, 0);
    private static final UUID ROTA = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");

    @TestConfiguration
    static class FixedClock {
        @Bean Clock clock() { return Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC); }
    }

    @Autowired MockMvc mvc;

    @MockitoBean ManageRouteInviteCodeUseCase useCase;
    @MockitoBean UserRepositoryPort userRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").build()));
        when(useCase.countUses(any())).thenReturn(0L);
    }

    private RouteInviteCode codigo() {
        return RouteInviteCode.builder().id(UUID.randomUUID()).routeId(ROTA)
                .code("RU7K2M").expiresAt(AGORA.plusDays(90)).build();
    }

    /// O código é o que dá acesso à rota. Aluno emitindo código pra própria rota
    /// destruiria o controle do admin sobre quem entra.
    @Test
    void alunoNaoGeraNemRevogaCodigo() throws Exception {
        mvc.perform(post("/api/routes/{id}/invite-codes", ROTA).with(student())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/routes/{id}/invite-codes", ROTA).with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/routes/{id}/invite-codes/{c}", ROTA, UUID.randomUUID()).with(student()))
                .andExpect(status().isForbidden());

        verify(useCase, never()).generate(any(), any(), any());
        verify(useCase, never()).revoke(any());
    }

    @Test
    void semTokenDevolve401() throws Exception {
        mvc.perform(get("/api/routes/{id}/invite-codes", ROTA))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void adminGeraCodigoSemCorpoUsandoValidadePadrao() throws Exception {
        when(useCase.generate(eq(ROTA), eq(null), eq(ADMIN_ID))).thenReturn(codigo());

        mvc.perform(post("/api/routes/{id}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.code").value("RU7K2M"))
                .andExpect(jsonPath("$.data.usable").value(true));

        verify(useCase).generate(ROTA, null, ADMIN_ID);
    }

    @Test
    void adminGeraComExpiracaoPropria() throws Exception {
        when(useCase.generate(any(), any(), any())).thenReturn(codigo());

        mvc.perform(post("/api/routes/{id}/invite-codes", ROTA).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"expiresAt":"2026-12-31T23:59:00"}"""))
                .andExpect(status().isCreated());

        verify(useCase).generate(ROTA, LocalDateTime.of(2026, 12, 31, 23, 59), ADMIN_ID);
    }

    /// A contagem de usos é o que diz ao admin se o código circulou ou se
    /// ninguém recebeu.
    @Test
    void listagemTrazQuantosEntraramPorCadaCodigo() throws Exception {
        var c = codigo();
        when(useCase.listByRoute(ROTA)).thenReturn(List.of(c));
        when(useCase.countUses(c.getId())).thenReturn(23L);

        mvc.perform(get("/api/routes/{id}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].uses").value(23))
                .andExpect(jsonPath("$.data[0].usable").value(true));
    }

    @Test
    void codigoRevogadoAparecComoInutilizavel() throws Exception {
        var revogado = RouteInviteCode.builder().id(UUID.randomUUID()).routeId(ROTA)
                .code("RU7K2M").expiresAt(AGORA.plusDays(90)).revokedAt(AGORA.minusHours(1)).build();
        when(useCase.listByRoute(ROTA)).thenReturn(List.of(revogado));

        mvc.perform(get("/api/routes/{id}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].usable").value(false))
                .andExpect(jsonPath("$.data[0].revokedAt").exists());
    }

    @Test
    void adminRevogaCodigo() throws Exception {
        UUID codeId = UUID.randomUUID();
        when(useCase.revoke(codeId)).thenReturn(codigo());

        mvc.perform(delete("/api/routes/{id}/invite-codes/{c}", ROTA, codeId).with(admin()))
                .andExpect(status().isOk());

        verify(useCase).revoke(codeId);
    }
}
