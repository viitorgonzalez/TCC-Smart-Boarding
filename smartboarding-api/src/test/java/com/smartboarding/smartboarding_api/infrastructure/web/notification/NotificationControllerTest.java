package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;
import com.smartboarding.smartboarding_api.domain.notification.port.in.ListNotificationsUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
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

@WebMvcTest(NotificationController.class)
@Import(NotificationControllerTest.FixedClock.class)
class NotificationControllerTest extends WebMvcTestSupport {

    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 9, 12, 0);
    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");

    @TestConfiguration
    static class FixedClock {
        @Bean
        Clock clock() {
            return Clock.fixed(NOW.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);
        }
    }

    @Autowired MockMvc mvc;

    @MockitoBean PublishNotificationUseCase publishNotificationUseCase;
    @MockitoBean ListNotificationsUseCase listNotificationsUseCase;
    @MockitoBean UserRepositoryPort userRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(
                User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br").build()));
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").build()));
        when(listNotificationsUseCase.listFor(any())).thenReturn(List.of());
    }

    private Notification aviso() {
        return Notification.builder().id(UUID.randomUUID()).title("Atraso")
                .body("O ônibus vai atrasar 20 minutos").routeId(ROUTE_ID)
                .createdAt(NOW.minusHours(1)).expiresAt(NOW.plusHours(3)).build();
    }

    @Test
    void alunoNaoPodePublicarAviso() throws Exception {
        mvc.perform(post("/api/notifications/broadcast").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"Falso","body":"x","routeId":"bbbbbbbb-0000-0000-0000-000000000001"}"""))
                .andExpect(status().isForbidden());

        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    @Test
    void alunoNaoPodeApagarAviso() throws Exception {
        mvc.perform(delete("/api/notifications").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                ["11111111-1111-1111-1111-111111111111"]"""))
                .andExpect(status().isForbidden());

        verify(publishNotificationUseCase, never()).deleteAll(any());
    }

    /// Ler o mural é de qualquer autenticado — é a caixa de avisos do aluno.
    @Test
    void alunoLeOProprioMural() throws Exception {
        mvc.perform(get("/api/notifications").with(student())).andExpect(status().isOk());

        verify(listNotificationsUseCase).listFor(STUDENT_ID);
    }

    @Test
    void muralSemTokenDevolve401() throws Exception {
        mvc.perform(get("/api/notifications")).andExpect(status().isUnauthorized());
    }

    @Test
    void publicarRepassaTituloCorpoRotaEDuracao() throws Exception {
        when(publishNotificationUseCase.publish(any(), any(), any(), any(), any()))
                .thenReturn(aviso());

        mvc.perform(post("/api/notifications/broadcast").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"Atraso","body":"O ônibus vai atrasar 20 minutos",\
                                "routeId":"bbbbbbbb-0000-0000-0000-000000000001","durationHours":4}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Atraso"))
                .andExpect(jsonPath("$.data.expired").value(false));

        verify(publishNotificationUseCase).publish("Atraso", "O ônibus vai atrasar 20 minutos",
                ROUTE_ID, 4, ADMIN_ID);
    }

    /// Todo aviso pertence a uma rota: sem routeId o envio não sai, senão viraria
    /// broadcast pra quem não pega aquele ônibus.
    @Test
    void avisoSemRotaERecusado() throws Exception {
        mvc.perform(post("/api/notifications/broadcast").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"Atraso","body":"corpo"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    @Test
    void avisoSemTituloERecusado() throws Exception {
        mvc.perform(post("/api/notifications/broadcast").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"","body":"corpo","routeId":"bbbbbbbb-0000-0000-0000-000000000001"}"""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void avisoVencidoVemMarcadoComoExpirado() throws Exception {
        var vencido = Notification.builder().id(UUID.randomUUID()).title("Antigo")
                .body("corpo").routeId(ROUTE_ID).createdAt(NOW.minusDays(2))
                .expiresAt(NOW.minusDays(1)).build();
        when(listNotificationsUseCase.listFor(STUDENT_ID)).thenReturn(List.of(vencido));

        mvc.perform(get("/api/notifications").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].expired").value(true));
    }

    /// Em lote de propósito: apagar vários avisos um a um seria N requisições e N
    /// recargas da tela.
    @Test
    void adminApagaVariosAvisosDeUmaVez() throws Exception {
        mvc.perform(delete("/api/notifications").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                ["11111111-1111-1111-1111-111111111111",\
                                "22222222-2222-2222-2222-222222222222"]"""))
                .andExpect(status().isOk());

        verify(publishNotificationUseCase).deleteAll(
                List.of(STUDENT_ID, ADMIN_ID));
    }
}
