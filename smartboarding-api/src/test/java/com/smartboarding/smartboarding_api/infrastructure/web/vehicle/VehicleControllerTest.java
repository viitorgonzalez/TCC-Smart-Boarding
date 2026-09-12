package com.smartboarding.smartboarding_api.infrastructure.web.vehicle;

import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import com.smartboarding.smartboarding_api.domain.vehicle.port.in.ManageVehiclesUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(VehicleController.class)
class VehicleControllerTest extends WebMvcTestSupport {

    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");
    private static final UUID VEHICLE_ID = UUID.fromString("eeeeeeee-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean ManageVehiclesUseCase manageVehiclesUseCase;

    /// A frota é informação operacional do admin — o aluno não precisa saber
    /// quantos ônibus existem nem a capacidade de cada um.
    @Test
    void frotaEVisivelSoParaOAdmin() throws Exception {
        mvc.perform(get("/api/routes/{routeId}/vehicles", ROUTE_ID).with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/routes/{routeId}/vehicles", ROUTE_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"label":"Falso","capacity":10}"""))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/routes/{routeId}/vehicles/{id}", ROUTE_ID, VEHICLE_ID).with(student()))
                .andExpect(status().isForbidden());

        verify(manageVehiclesUseCase, never()).listByRoute(any());
        verify(manageVehiclesUseCase, never()).add(any());
    }

    @Test
    void adminListaAFrotaDaRota() throws Exception {
        when(manageVehiclesUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(
                Vehicle.builder().id(VEHICLE_ID).routeId(ROUTE_ID).label("Ônibus 01").capacity(44).build()));

        mvc.perform(get("/api/routes/{routeId}/vehicles", ROUTE_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].label").value("Ônibus 01"))
                .andExpect(jsonPath("$.data[0].capacity").value(44));
    }

    @Test
    void adicionarVeiculoAmarraNaRotaDaUrl() throws Exception {
        when(manageVehiclesUseCase.add(any())).thenAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/api/routes/{routeId}/vehicles", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"label":"Van 01","capacity":15}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.label").value("Van 01"));

        var captor = org.mockito.ArgumentCaptor.forClass(Vehicle.class);
        verify(manageVehiclesUseCase).add(captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().getRouteId()).isEqualTo(ROUTE_ID);
    }

    /// Capacidade é o que alimenta a RN16: zero ou negativo quebraria a alocação.
    @Test
    void capacidadeNaoPositivaERecusada() throws Exception {
        mvc.perform(post("/api/routes/{routeId}/vehicles", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"label":"Van 01","capacity":0}"""))
                .andExpect(status().isBadRequest());

        mvc.perform(post("/api/routes/{routeId}/vehicles", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"label":"Van 01"}"""))
                .andExpect(status().isBadRequest());

        verify(manageVehiclesUseCase, never()).add(any());
    }

    @Test
    void adminRemoveVeiculo() throws Exception {
        mvc.perform(delete("/api/routes/{routeId}/vehicles/{id}", ROUTE_ID, VEHICLE_ID).with(admin()))
                .andExpect(status().isOk());

        verify(manageVehiclesUseCase).remove(VEHICLE_ID);
    }
}
