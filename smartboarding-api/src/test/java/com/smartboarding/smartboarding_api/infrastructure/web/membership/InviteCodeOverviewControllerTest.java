package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/// A tela de códigos cruza rotas, então esta listagem é a única que precisa
/// dizer de que rota cada código é.
@WebMvcTest(InviteCodeOverviewController.class)
@Import(InviteCodeOverviewControllerTest.FixedClock.class)
class InviteCodeOverviewControllerTest extends WebMvcTestSupport {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 11, 10, 0);
    private static final UUID MINHA_ROTA = UUID.randomUUID();
    private static final UUID ROTA_ALHEIA = UUID.randomUUID();
    private static final UUID UNIFOR = UUID.randomUUID();
    private static final UUID IFMG = UUID.randomUUID();

    @TestConfiguration
    static class FixedClock {
        @Bean
        Clock clock() {
            return Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
        }
    }

    @Autowired MockMvc mvc;

    @MockitoBean ManageRouteInviteCodeUseCase useCase;
    @MockitoBean RouteRepositoryPort routeRepository;
    @MockitoBean InstitutionRepositoryPort institutionRepository;
    @MockitoBean AdminGuard guard;

    private RouteInviteCode codigo(String code, UUID rota, UUID instituicao, LocalDateTime expira) {
        return RouteInviteCode.builder().id(UUID.randomUUID()).routeId(rota)
                .code(code).expiresAt(expira).institutionId(instituicao).build();
    }

    @BeforeEach
    void setUp() {
        when(guard.routes(any())).thenReturn(Set.of(MINHA_ROTA));
        when(guard.institutions(any())).thenReturn(Set.of(IFMG));
        when(useCase.countUses(any())).thenReturn(0L);
        when(routeRepository.findAllByIsActiveTrue()).thenReturn(List.of(
                Route.builder().id(MINHA_ROTA).name("Rota Universitária de Formiga").build(),
                Route.builder().id(ROTA_ALHEIA).name("Rota de Outra Cidade").build()));
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(IFMG).name("IFMG").build(),
                Institution.builder().id(UNIFOR).name("UNIFOR-MG").build()));
    }

    @Test
    void cadaCodigoDizDeQueRotaE() throws Exception {
        when(useCase.listByRoute(MINHA_ROTA)).thenReturn(List.of(
                codigo("AAA111", MINHA_ROTA, IFMG, AGORA.plusDays(7))));

        mvc.perform(get("/api/invite-codes").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].routeName").value("Rota Universitária de Formiga"))
                .andExpect(jsonPath("$.data[0].institutionName").value("IFMG"));
    }

    /// A listagem só percorre as rotas do admin — rota alheia nem é consultada.
    @Test
    void naoTrazCodigoDeRotaAlheia() throws Exception {
        when(useCase.listByRoute(MINHA_ROTA)).thenReturn(List.of(
                codigo("AAA111", MINHA_ROTA, IFMG, AGORA.plusDays(7))));
        when(useCase.listByRoute(ROTA_ALHEIA)).thenReturn(List.of(
                codigo("BBB222", ROTA_ALHEIA, UNIFOR, AGORA.plusDays(7))));

        mvc.perform(get("/api/invite-codes").with(admin()))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].code").value("AAA111"));
    }

    @Test
    void naoTrazCodigoDeInstituicaoAlheiaNaMesmaRota() throws Exception {
        when(useCase.listByRoute(MINHA_ROTA)).thenReturn(List.of(
                codigo("AAA111", MINHA_ROTA, IFMG, AGORA.plusDays(7)),
                codigo("CCC333", MINHA_ROTA, UNIFOR, AGORA.plusDays(7))));

        mvc.perform(get("/api/invite-codes").with(admin()))
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].code").value("AAA111"));
    }

    /// Vencido no fim: o admin abre a tela pra decidir se precisa gerar outro, e
    /// código morto no topo empurra o que interessa pra fora da primeira tela.
    @Test
    void utilizavelPrimeiroEOQueVenceAntesNaFrente() throws Exception {
        when(useCase.listByRoute(MINHA_ROTA)).thenReturn(List.of(
                codigo("TARDE0", MINHA_ROTA, IFMG, AGORA.plusDays(30)),
                codigo("MORTO0", MINHA_ROTA, IFMG, AGORA.minusDays(1)),
                codigo("CEDO00", MINHA_ROTA, IFMG, AGORA.plusDays(2))));

        mvc.perform(get("/api/invite-codes").with(admin()))
                .andExpect(jsonPath("$.data[0].code").value("CEDO00"))
                .andExpect(jsonPath("$.data[1].code").value("TARDE0"))
                .andExpect(jsonPath("$.data[2].code").value("MORTO0"));
    }

    @Test
    void alunoNaoVeCodigoNenhum() throws Exception {
        mvc.perform(get("/api/invite-codes").with(student()))
                .andExpect(status().isForbidden());
    }
}
