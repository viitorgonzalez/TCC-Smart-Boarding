package com.smartboarding.smartboarding_api.infrastructure.web.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.CreateRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.DeleteRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.FindRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteScheduleUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RouteController.class)
class RouteControllerTest extends WebMvcTestSupport {

    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean CreateRouteUseCase createRouteUseCase;
    @MockitoBean FindRouteUseCase findRouteUseCase;
    @MockitoBean UpdateRouteUseCase updateRouteUseCase;
    @MockitoBean DeleteRouteUseCase deleteRouteUseCase;
    @MockitoBean UpdateRouteScheduleUseCase updateRouteScheduleUseCase;

    private Route rota() {
        return Route.builder().id(ROUTE_ID).name("Rota Universitária").description("via centro")
                .openTime(LocalTime.of(6, 0)).closeTime(LocalTime.of(17, 0)).isActive(true).build();
    }

    /// GET /api/routes é permitAll: a tela de cadastro precisa listar as rotas
    /// antes de existir conta.
    @Test
    void listarRotasEPublico() throws Exception {
        when(findRouteUseCase.findAllActive()).thenReturn(List.of(rota()));

        mvc.perform(get("/api/routes"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Rota Universitária"))
                .andExpect(jsonPath("$.data[0].openTime").value("06:00:00"));
    }

    @Test
    void verUmaRotaEPublico() throws Exception {
        when(findRouteUseCase.findById(ROUTE_ID)).thenReturn(rota());

        mvc.perform(get("/api/routes/{id}", ROUTE_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(ROUTE_ID.toString()));
    }

    @Test
    void rotaInexistenteDevolve404() throws Exception {
        when(findRouteUseCase.findById(any())).thenThrow(new NotFoundException("Rota não encontrada"));

        mvc.perform(get("/api/routes/{id}", ROUTE_ID)).andExpect(status().isNotFound());
    }

    @Test
    void criarRotaEDoAdmin() throws Exception {
        mvc.perform(post("/api/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rota Falsa"}"""))
                .andExpect(status().isForbidden());

        verify(createRouteUseCase, never()).execute(any());
    }

    @Test
    void adminCriaRotaERecebe201() throws Exception {
        when(createRouteUseCase.execute(any())).thenReturn(rota());

        mvc.perform(post("/api/routes").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rota Universitária","description":"via centro",\
                                "openTime":"06:00:00","closeTime":"17:00:00"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Rota Universitária"));
    }

    @Test
    void rotaSemNomeERecusada() throws Exception {
        mvc.perform(post("/api/routes").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":""}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        verify(createRouteUseCase, never()).execute(any());
    }

    @Test
    void nomeDuplicadoDevolve409() throws Exception {
        when(createRouteUseCase.execute(any()))
                .thenThrow(new ConflictException("ROUTE_ALREADY_EXISTS", "Rota já cadastrada"));

        mvc.perform(post("/api/routes").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rota Universitária"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ROUTE_ALREADY_EXISTS"));
    }

    @Test
    void editarRotaRepassaIsActive() throws Exception {
        when(updateRouteUseCase.execute(eq(ROUTE_ID), any(), eq(true))).thenReturn(rota());

        mvc.perform(patch("/api/routes/{id}", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Rota Universitária","isActive":true}"""))
                .andExpect(status().isOk());

        verify(updateRouteUseCase).execute(eq(ROUTE_ID), any(), eq(true));
    }

    /// Mudar o horário dispara aviso aos alunos — o motivo vai no aviso, então
    /// precisa chegar inteiro no use case.
    @Test
    void mudarHorarioRepassaOMotivo() throws Exception {
        when(updateRouteScheduleUseCase.execute(any(), any(), any(), any())).thenReturn(rota());

        mvc.perform(patch("/api/routes/{id}/schedule", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"openTime":"05:30:00","closeTime":"18:00:00",\
                                "reason":"Prova na Unifor"}"""))
                .andExpect(status().isOk());

        verify(updateRouteScheduleUseCase).execute(ROUTE_ID,
                LocalTime.of(5, 30), LocalTime.of(18, 0), "Prova na Unifor");
    }

    @Test
    void mudarHorarioSemOsHorariosERecusado() throws Exception {
        mvc.perform(patch("/api/routes/{id}/schedule", ROUTE_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"sem horário"}"""))
                .andExpect(status().isBadRequest());

        verify(updateRouteScheduleUseCase, never()).execute(any(), any(), any(), any());
    }

    @Test
    void desativarRotaEDoAdmin() throws Exception {
        mvc.perform(delete("/api/routes/{id}", ROUTE_ID).with(student()))
                .andExpect(status().isForbidden());

        mvc.perform(delete("/api/routes/{id}", ROUTE_ID).with(admin()))
                .andExpect(status().isOk());

        verify(deleteRouteUseCase).execute(ROUTE_ID);
    }
}
