package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.NotificationFrequency;
import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import com.smartboarding.smartboarding_api.domain.notification.port.in.ManageScheduledNotificationUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
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
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ScheduledNotificationController.class)
class ScheduledNotificationControllerTest extends WebMvcTestSupport {

    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean ManageScheduledNotificationUseCase useCase;

    private ScheduledNotification aviso() {
        return ScheduledNotification.builder().id(UUID.randomUUID()).routeId(ROUTE_ID)
                .title("Lista aberta").body("A lista de hoje já está aberta")
                .frequency(NotificationFrequency.WEEKDAYS).sendAt(LocalTime.of(6, 0))
                .durationHours(4).active(true).build();
    }

    @Test
    void configurarAvisoAutomaticoEDoAdmin() throws Exception {
        mvc.perform(get("/api/notifications/scheduled").param("routeId", ROUTE_ID.toString())
                        .with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/notifications/scheduled").with(student())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());

        verify(useCase, never()).listByRoute(any());
        verify(useCase, never()).save(any());
    }

    @Test
    void listarFiltraPelaRota() throws Exception {
        when(useCase.listByRoute(ROUTE_ID)).thenReturn(List.of(aviso()));

        mvc.perform(get("/api/notifications/scheduled").param("routeId", ROUTE_ID.toString())
                        .with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].title").value("Lista aberta"))
                .andExpect(jsonPath("$.data[0].frequency").value("WEEKDAYS"));
    }

    @Test
    void listarSemRouteIdERecusado() throws Exception {
        mvc.perform(get("/api/notifications/scheduled").with(admin()))
                .andExpect(status().isBadRequest());
    }

    /// Aviso nasce ativo: configurar e ter que ligar em seguida seria um passo a
    /// mais sem ganho nenhum.
    @Test
    void avisoNasceAtivo() throws Exception {
        when(useCase.save(any())).thenAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/api/notifications/scheduled").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001","title":"Lista aberta",\
                                "body":"A lista de hoje já está aberta","frequency":"WEEKDAYS",\
                                "sendAt":"06:00:00","durationHours":4}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.active").value(true));

        var captor = org.mockito.ArgumentCaptor.forClass(ScheduledNotification.class);
        verify(useCase).save(captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().isActive()).isTrue();
        org.assertj.core.api.Assertions.assertThat(captor.getValue().getSendAt())
                .isEqualTo(LocalTime.of(6, 0));
    }

    @Test
    void avisoSemFrequenciaOuHorarioERecusado() throws Exception {
        mvc.perform(post("/api/notifications/scheduled").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001","title":"x","body":"y"}"""))
                .andExpect(status().isBadRequest());

        verify(useCase, never()).save(any());
    }

    /// dayOfWeek é 1..7; fora disso o WEEKLY nunca casaria com dia nenhum e o
    /// aviso ficaria mudo pra sempre.
    @Test
    void diaDaSemanaForaDoIntervaloERecusado() throws Exception {
        mvc.perform(post("/api/notifications/scheduled").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001","title":"x","body":"y",\
                                "frequency":"WEEKLY","sendAt":"06:00:00","dayOfWeek":9}"""))
                .andExpect(status().isBadRequest());

        verify(useCase, never()).save(any());
    }

    @Test
    void desligarAvisoRepassaFalse() throws Exception {
        UUID id = UUID.randomUUID();
        when(useCase.toggle(any(), anyBoolean())).thenReturn(aviso());

        mvc.perform(patch("/api/notifications/scheduled/{id}", id).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"active":false}"""))
                .andExpect(status().isOk());

        verify(useCase).toggle(id, false);
    }

    @Test
    void avisoInexistenteDevolve404() throws Exception {
        when(useCase.toggle(any(), anyBoolean()))
                .thenThrow(new NotFoundException("Aviso automático não encontrado"));

        mvc.perform(patch("/api/notifications/scheduled/{id}", UUID.randomUUID()).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"active":true}"""))
                .andExpect(status().isNotFound());
    }

    @Test
    void adminApagaAviso() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(delete("/api/notifications/scheduled/{id}", id).with(admin()))
                .andExpect(status().isOk());

        verify(useCase).delete(id);
    }
}
