package com.smartboarding.smartboarding_api.infrastructure.web.stop;

import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(StopController.class)
class StopControllerTest extends WebMvcTestSupport {

    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");
    private static final UUID STOP_ID = UUID.fromString("dddddddd-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean ManageStopsUseCase manageStopsUseCase;
    @MockitoBean AdminGuard guard;

    private Stop parada() {
        return Stop.builder().id(STOP_ID).routeId(ROUTE_ID).name("Rodoviária")
                .latitude(-20.46).longitude(-45.42).sequence(1).isMainPoint(true).build();
    }

    /// O aluno vê o mapa da rota, então listar parada é de qualquer autenticado —
    /// mas mexer na rota é do admin.
    @Test
    void alunoVeAsParadasMasNaoAsAltera() throws Exception {
        when(manageStopsUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(parada()));

        mvc.perform(get("/api/routes/{routeId}/stops", ROUTE_ID).with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Rodoviária"))
                .andExpect(jsonPath("$.data[0].isMainPoint").value(true));

        mvc.perform(post("/api/routes/{routeId}/stops", ROUTE_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Parada Falsa"}"""))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/routes/{routeId}/stops/{stopId}", ROUTE_ID, STOP_ID).with(student()))
                .andExpect(status().isForbidden());

        verify(manageStopsUseCase, never()).add(any());
        verify(manageStopsUseCase, never()).remove(any());
    }

    @Test
    void semTokenDevolve401() throws Exception {
        mvc.perform(get("/api/routes/{routeId}/stops", ROUTE_ID))
                .andExpect(status().isUnauthorized());
    }

    /// Sem sequence a parada entra no fim — o controller manda 0 e o use case
    /// resolve a posição.
    @Test
    void criarSemSequenciaMandaZero() throws Exception {
        when(manageStopsUseCase.add(any())).thenReturn(parada());

        mvc.perform(post("/api/routes/{routeId}/stops", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rodoviária","latitude":-20.46,"longitude":-45.42}"""))
                .andExpect(status().isCreated());

        var captor = org.mockito.ArgumentCaptor.forClass(Stop.class);
        verify(manageStopsUseCase).add(captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().getSequence()).isZero();
        org.assertj.core.api.Assertions.assertThat(captor.getValue().getRouteId()).isEqualTo(ROUTE_ID);
    }

    @Test
    void criarComSequenciaInsereNaPosicao() throws Exception {
        when(manageStopsUseCase.add(any())).thenReturn(parada());

        mvc.perform(post("/api/routes/{routeId}/stops", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Nova","sequence":2}"""))
                .andExpect(status().isCreated());

        var captor = org.mockito.ArgumentCaptor.forClass(Stop.class);
        verify(manageStopsUseCase).add(captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().getSequence()).isEqualTo(2);
    }

    @Test
    void paradaSemNomeERecusada() throws Exception {
        mvc.perform(post("/api/routes/{routeId}/stops", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":""}"""))
                .andExpect(status().isBadRequest());

        verify(manageStopsUseCase, never()).add(any());
    }

    @Test
    void editarRepassaNomeECoordenadas() throws Exception {
        when(manageStopsUseCase.update(any(), any(), any(), any())).thenReturn(parada());

        mvc.perform(patch("/api/routes/{routeId}/stops/{stopId}", ROUTE_ID, STOP_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rodoviária Nova","latitude":-20.5,"longitude":-45.5}"""))
                .andExpect(status().isOk());

        verify(manageStopsUseCase).update(STOP_ID, "Rodoviária Nova", -20.5, -45.5);
    }

    @Test
    void adminRemoveParada() throws Exception {
        mvc.perform(delete("/api/routes/{routeId}/stops/{stopId}", ROUTE_ID, STOP_ID).with(admin()))
                .andExpect(status().isOk());

        verify(manageStopsUseCase).remove(STOP_ID);
    }

    // ─── O bug do ponto principal ────────────────────────────────────────────

    /// Nada em src/main escrevia is_main_point antes da V32 -- e o contrato
    /// HTTP nem tinha o campo. Sem esta entrada, toda parada criada pela API
    /// nascia comum e o trajeto recusava todo checkpoint nela.
    @Test
    void criarParadaComInstituicaoChegaNoUseCase() throws Exception {
        UUID instituicao = UUID.fromString("cccccccc-0000-0000-0000-000000000001");
        when(manageStopsUseCase.add(any())).thenAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/api/routes/{routeId}/stops", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"UNIFOR-MG","latitude":-20.46,"longitude":-45.42,
                                 "institutionId":"%s"}
                                """.formatted(instituicao)))
                .andExpect(status().isCreated());

        ArgumentCaptor<Stop> captor = ArgumentCaptor.forClass(Stop.class);
        verify(manageStopsUseCase).add(captor.capture());
        assertThat(captor.getValue().getInstitutionId()).isEqualTo(instituicao);
    }

    @Test
    void institutionIdVoltaNaResposta() throws Exception {
        UUID instituicao = UUID.fromString("cccccccc-0000-0000-0000-000000000001");
        Stop comVinculo = parada();
        comVinculo.setInstitutionId(instituicao);
        when(manageStopsUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(comVinculo));

        mvc.perform(get("/api/routes/{routeId}/stops", ROUTE_ID).with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].institutionId").value(instituicao.toString()));
    }

    /// Arrastar o pino no mapa manda só as coordenadas. Se isso caísse na
    /// sobrecarga completa, o institutionId nulo do corpo desvincularia a
    /// instituição -- e a parada deixaria de aceitar checkpoint sem ninguém
    /// ter pedido nada disso.
    @Test
    void moverAParadaNaoDesfazOVinculoComAInstituicao() throws Exception {
        when(manageStopsUseCase.update(any(), any(), any(), any()))
                .thenReturn(parada());

        mvc.perform(patch("/api/routes/{routeId}/stops/{stopId}", ROUTE_ID, STOP_ID)
                        .with(admin()).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"latitude":-20.47,"longitude":-45.43}
                                """))
                .andExpect(status().isOk());

        verify(manageStopsUseCase).update(STOP_ID, null, -20.47, -45.43);
        verify(manageStopsUseCase, never())
                .update(any(), any(), any(), any(), any(), anyBoolean());
    }

    @Test
    void declararOVinculoUsaASobrecargaCompleta() throws Exception {
        UUID instituicao = UUID.fromString("cccccccc-0000-0000-0000-000000000001");
        when(manageStopsUseCase.update(any(), any(), any(), any(), any(), anyBoolean()))
                .thenReturn(parada());

        mvc.perform(patch("/api/routes/{routeId}/stops/{stopId}", ROUTE_ID, STOP_ID)
                        .with(admin()).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"institutionId":"%s"}
                                """.formatted(instituicao)))
                .andExpect(status().isOk());

        verify(manageStopsUseCase).update(STOP_ID, null, null, null, instituicao, false);
    }
}
