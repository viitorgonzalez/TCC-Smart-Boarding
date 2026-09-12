package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.domain.notification.port.in.RegisterDeviceTokenUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.RemoveDeviceTokenUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(DeviceController.class)
class DeviceControllerTest extends WebMvcTestSupport {

    @Autowired MockMvc mvc;

    @MockitoBean RegisterDeviceTokenUseCase registerDeviceTokenUseCase;
    @MockitoBean RemoveDeviceTokenUseCase removeDeviceTokenUseCase;
    @MockitoBean UserRepositoryPort userRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(
                User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br").build()));
    }

    /// O dono do token é quem está no JWT. Aceitar userId do corpo deixaria um
    /// usuário registrar dispositivo em nome de outro e receber os push dele.
    @Test
    void tokenEAmarradoAoUsuarioDoJwt() throws Exception {
        mvc.perform(post("/api/devices/token").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"fcm-token-abc","platform":"android"}"""))
                .andExpect(status().isOk());

        verify(registerDeviceTokenUseCase).execute(STUDENT_ID, "fcm-token-abc", "android");
    }

    @Test
    void semTokenDeAutenticacaoDevolve401() throws Exception {
        mvc.perform(post("/api/devices/token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"fcm-token-abc","platform":"android"}"""))
                .andExpect(status().isUnauthorized());

        verify(registerDeviceTokenUseCase, never()).execute(any(), anyString(), anyString());
    }

    @Test
    void tokenVazioERecusado() throws Exception {
        mvc.perform(post("/api/devices/token").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"","platform":"android"}"""))
                .andExpect(status().isBadRequest());

        verify(registerDeviceTokenUseCase, never()).execute(any(), anyString(), anyString());
    }

    @Test
    void usuarioApagadoComTokenValidoDevolve401() throws Exception {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.empty());

        mvc.perform(post("/api/devices/token").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"token":"fcm-token-abc","platform":"android"}"""))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutRemoveOsTokensDoProprioUsuario() throws Exception {
        mvc.perform(delete("/api/devices/token").with(student()))
                .andExpect(status().isOk());

        verify(removeDeviceTokenUseCase).execute(STUDENT_ID);
    }
}
