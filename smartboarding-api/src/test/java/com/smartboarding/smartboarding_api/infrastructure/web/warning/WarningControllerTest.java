package com.smartboarding.smartboarding_api.infrastructure.web.warning;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;
import com.smartboarding.smartboarding_api.domain.warning.port.in.ManageWarningUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(WarningController.class)
class WarningControllerTest extends WebMvcTestSupport {

    @Autowired MockMvc mvc;

    @MockitoBean ManageWarningUseCase manageWarningUseCase;
    @MockitoBean UserRepositoryPort userRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(
                User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br")
                        .fullName("Fernanda Lima").build()));
        when(manageWarningUseCase.list(any())).thenReturn(List.of());
    }

    private Warning advertencia() {
        return Warning.builder().id(UUID.randomUUID())
                .user(User.builder().id(STUDENT_ID).fullName("Fernanda Lima").build())
                .dailyList(DailyList.builder().date(LocalDate.of(2026, 9, 9)).build())
                .reason("Entrou na lista fora do horário")
                .issuedBy(User.builder().id(ADMIN_ID).fullName("Naiara").build())
                .build();
    }

    /// /api/warnings?userId=... é do admin. Se o aluno alcançasse esse endpoint,
    /// passaria a ler advertência de qualquer colega trocando o parâmetro.
    @Test
    void alunoNaoListaAdvertenciaDeTerceiro() throws Exception {
        mvc.perform(get("/api/warnings").param("userId", ADMIN_ID.toString()).with(student()))
                .andExpect(status().isForbidden());

        verify(manageWarningUseCase, never()).list(ADMIN_ID);
    }

    /// /me ignora qualquer parâmetro e usa o id do token — é o que torna o
    /// endpoint seguro pro aluno.
    @Test
    void meUsaOUsuarioDoTokenEIgnoraParametro() throws Exception {
        when(manageWarningUseCase.list(STUDENT_ID)).thenReturn(List.of(advertencia()));

        mvc.perform(get("/api/warnings/me").param("userId", ADMIN_ID.toString()).with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].studentName").value("Fernanda Lima"))
                .andExpect(jsonPath("$.data[0].reason").value("Entrou na lista fora do horário"))
                .andExpect(jsonPath("$.data[0].listDate").value("2026-09-09"));

        verify(manageWarningUseCase).list(STUDENT_ID);
        verify(manageWarningUseCase, never()).list(ADMIN_ID);
    }

    @Test
    void meSemTokenDevolve401() throws Exception {
        mvc.perform(get("/api/warnings/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void tokenDeUsuarioApagadoDevolve401() throws Exception {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.empty());

        mvc.perform(get("/api/warnings/me").with(student())).andExpect(status().isUnauthorized());
    }

    @Test
    void adminListaFiltrandoPorAluno() throws Exception {
        when(manageWarningUseCase.list(STUDENT_ID)).thenReturn(List.of(advertencia()));

        mvc.perform(get("/api/warnings").param("userId", STUDENT_ID.toString()).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));

        verify(manageWarningUseCase).list(STUDENT_ID);
    }

    @Test
    void adminSemFiltroListaTodas() throws Exception {
        mvc.perform(get("/api/warnings").with(admin())).andExpect(status().isOk());

        verify(manageWarningUseCase).list(null);
    }

    @Test
    void apagarAdvertenciaEDoAdmin() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(delete("/api/warnings/{id}", id).with(student()))
                .andExpect(status().isForbidden());

        mvc.perform(delete("/api/warnings/{id}", id).with(admin()))
                .andExpect(status().isOk());

        verify(manageWarningUseCase).delete(id);
    }
}
