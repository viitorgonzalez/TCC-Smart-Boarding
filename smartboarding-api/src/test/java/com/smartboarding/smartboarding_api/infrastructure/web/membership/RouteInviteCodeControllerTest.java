package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;

import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
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
import com.smartboarding.smartboarding_api.shared.exception.ForbiddenException;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
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
    @MockitoBean InstitutionRepositoryPort institutionRepository;
    @MockitoBean AdminGuard guard;
    @MockitoBean RouteRepositoryPort routeRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").build()));
        when(useCase.countUses(any())).thenReturn(0L);
        // O guarda e mockado: sem isto ele devolveria null como admin logado e
        // os stubs de generate nao casariam.
        when(guard.id(any())).thenReturn(ADMIN_ID);
        when(guard.institutions(any())).thenReturn(Set.of());
        when(useCase.findById(any())).thenReturn(codigo());
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

        verify(useCase, never()).generate(any(), any(), any(), any());
        verify(useCase, never()).revoke(any());
    }

    @Test
    void semTokenDevolve401() throws Exception {
        mvc.perform(get("/api/routes/{id}/invite-codes", ROTA))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void adminGeraCodigoSemCorpoUsandoValidadePadrao() throws Exception {
        when(useCase.generate(eq(ROTA), eq(null), eq(null), eq(ADMIN_ID))).thenReturn(codigo());

        mvc.perform(post("/api/routes/{id}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.code").value("RU7K2M"))
                .andExpect(jsonPath("$.data.usable").value(true));

        verify(useCase).generate(ROTA, null, null, ADMIN_ID);
    }

    @Test
    void adminGeraComExpiracaoPropria() throws Exception {
        when(useCase.generate(any(), any(), any(), any())).thenReturn(codigo());

        mvc.perform(post("/api/routes/{id}/invite-codes", ROTA).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"expiresAt":"2026-12-31T23:59:00"}"""))
                .andExpect(status().isCreated());

        verify(useCase).generate(ROTA, LocalDateTime.of(2026, 12, 31, 23, 59), null, ADMIN_ID);
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

    // ─── Alcance do admin ────────────────────────────────────────────────────

    private static final UUID UNIFOR = UUID.randomUUID();
    private static final UUID IFMG = UUID.randomUUID();

    private RouteInviteCode codigoDa(UUID instituicao) {
        return RouteInviteCode.builder().id(UUID.randomUUID()).routeId(ROTA)
                .code("UNI123").expiresAt(AGORA.plusDays(90))
                .institutionId(instituicao).build();
    }

    /// Ver o código já é poder distribuí-lo: se o da UNIFOR aparece pro admin do
    /// IFMG, ele manda no grupo errado e a trava de entrada vira enfeite.
    @Test
    void codigoDeOutraInstituicaoNaoAparece() throws Exception {
        when(guard.institutions(any())).thenReturn(Set.of(IFMG));
        when(useCase.listByRoute(ROTA)).thenReturn(List.of(
                codigoDa(UNIFOR), codigoDa(IFMG)));

        mvc.perform(get("/api/routes/{r}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].institutionId").value(IFMG.toString()));
    }

    /// Código aberto não é de ninguém, então aparece pra qualquer admin da rota.
    @Test
    void codigoAbertoApareceParaTodoAdminDaRota() throws Exception {
        when(guard.institutions(any())).thenReturn(Set.of(IFMG));
        when(useCase.listByRoute(ROTA)).thenReturn(List.of(codigoDa(null)));

        mvc.perform(get("/api/routes/{r}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    void naoGeraCodigoDeInstituicaoAlheia() throws Exception {
        doThrow(new ForbiddenException("NOT_YOUR_INSTITUTION", "Você não administra essa instituição."))
                .when(guard).ownsInstitution(any(), eq(UNIFOR));

        mvc.perform(post("/api/routes/{r}/invite-codes", ROTA).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"institutionId\":\"" + UNIFOR + "\"}"))
                .andExpect(status().isForbidden());

        verify(useCase, never()).generate(any(), any(), any(), any());
    }

    @Test
    void naoRevogaCodigoDeInstituicaoAlheia() throws Exception {
        UUID codeId = UUID.randomUUID();
        when(useCase.findById(codeId)).thenReturn(codigoDa(UNIFOR));
        doThrow(new ForbiddenException("NOT_YOUR_INSTITUTION", "Você não administra essa instituição."))
                .when(guard).ownsInstitution(any(), eq(UNIFOR));

        mvc.perform(delete("/api/routes/{r}/invite-codes/{c}", ROTA, codeId).with(admin()))
                .andExpect(status().isForbidden());

        verify(useCase, never()).revoke(any());
    }

    @Test
    void naoMexeEmCodigoDeRotaQueNaoAdministra() throws Exception {
        doThrow(new ForbiddenException("NOT_YOUR_ROUTE", "Essa rota não é sua."))
                .when(guard).ownsRoute(any(), eq(ROTA));

        mvc.perform(get("/api/routes/{r}/invite-codes", ROTA).with(admin()))
                .andExpect(status().isForbidden());
    }
}
