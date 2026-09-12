package com.smartboarding.smartboarding_api.infrastructure.web.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateStatus;
import com.smartboarding.smartboarding_api.domain.profile.port.in.ManageProfileUpdateUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProfileController.class)
class ProfileControllerTest extends WebMvcTestSupport {

    @Autowired MockMvc mvc;

    @MockitoBean ManageProfileUpdateUseCase useCase;
    @MockitoBean UserRepositoryPort userRepository;
    @MockitoBean com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase
            userInstitutionsUseCase;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(
                User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br")
                        .fullName("Fernanda Lima").build()));
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara").build()));
        when(userRepository.findAll()).thenReturn(List.of());
        when(useCase.listPending()).thenReturn(List.of());
        when(useCase.myPending(any())).thenReturn(Optional.empty());
        when(useCase.request(any(), any())).thenAnswer(inv -> {
            ProfileUpdateRequest p = inv.getArgument(1);
            p.setId(UUID.randomUUID());
            p.setUserId(inv.getArgument(0));
            p.setStatus(ProfileUpdateStatus.PENDING);
            return p;
        });
    }

    @Test
    void semTokenNaoPedeAlteracao() throws Exception {
        mvc.perform(post("/api/me/profile-requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"phone":"37988887777"}"""))
                .andExpect(status().isUnauthorized());

        verify(useCase, never()).request(any(), any());
    }

    /// O id sai do token: aceitar userId do corpo deixaria um aluno pedir
    /// alteracao no perfil de outro.
    @Test
    void pedidoUsaOUsuarioDoToken() throws Exception {
        mvc.perform(post("/api/me/profile-requests").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"phone":"37988887777","userId":"22222222-2222-2222-2222-222222222222"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.userId").value(STUDENT_ID.toString()));

        verify(useCase).request(eq(STUDENT_ID), any());
    }

    @Test
    void pedidoPendenteDuplicadoDevolve409() throws Exception {
        // doThrow em vez de when(...): o when reavalia o stub do setUp com
        // argumentos nulos antes de trocar o comportamento.
        org.mockito.Mockito.doThrow(new ConflictException(
                        "PENDING_REQUEST_EXISTS", "Você já tem uma solicitação em análise."))
                .when(useCase).request(any(), any());

        mvc.perform(post("/api/me/profile-requests").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"phone":"37988887777"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PENDING_REQUEST_EXISTS"));
    }

    @Test
    void semPendenteODadoVemNuloEmVezDe404() throws Exception {
        mvc.perform(get("/api/me/profile-requests/pending").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").doesNotExist());
    }

    /// A fila e do admin: um aluno vendo os pedidos leria nome, telefone e
    /// endereco que colegas pediram pra mudar.
    @Test
    void filaEDecisoesSaoDoAdmin() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(get("/api/profile-requests").with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/profile-requests/{id}/approve", id).with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/profile-requests/{id}/reject", id).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"nao"}"""))
                .andExpect(status().isForbidden());

        verify(useCase, never()).listPending();
        verify(useCase, never()).approve(any(), any());
        verify(useCase, never()).reject(any(), anyString(), any());
    }

    @Test
    void adminAprovaRegistrandoQuemDecidiu() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(post("/api/profile-requests/{id}/approve", id).with(admin()))
                .andExpect(status().isOk());

        verify(useCase).approve(id, ADMIN_ID);
    }

    /// Sem motivo o aluno refaz o mesmo pedido sem saber o que corrigir.
    @Test
    void recusarSemMotivoERecusado() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(post("/api/profile-requests/{id}/reject", id).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":""}"""))
                .andExpect(status().isBadRequest());

        verify(useCase, never()).reject(any(), anyString(), any());
    }

    @Test
    void adminRecusaComMotivo() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(post("/api/profile-requests/{id}/reject", id).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Nome não confere com o documento"}"""))
                .andExpect(status().isOk());

        verify(useCase).reject(id, "Nome não confere com o documento", ADMIN_ID);
    }

    /// As instituicoes sao do proprio aluno: e pre-requisito pra entrar em rota,
    /// entao o endpoint vive sob /me e usa o id do token.
    @Test
    void instituicoesUsamOUsuarioDoToken() throws Exception {
        UUID inst = UUID.randomUUID();
        when(userInstitutionsUseCase.institutionsOf(STUDENT_ID)).thenReturn(List.of(inst));

        mvc.perform(get("/api/me/institutions").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0]").value(inst.toString()));

        mvc.perform(post("/api/me/institutions/{id}", inst).with(student()))
                .andExpect(status().isCreated());

        verify(userInstitutionsUseCase).add(STUDENT_ID, inst);
    }

    @Test
    void semTokenNaoMexeNasInstituicoes() throws Exception {
        UUID inst = UUID.randomUUID();

        mvc.perform(get("/api/me/institutions")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/institutions/{id}", inst))
                .andExpect(status().isUnauthorized());

        verify(userInstitutionsUseCase, never()).add(any(), any());
    }

    @Test
    void alunoRemoveAPropriaInstituicao() throws Exception {
        UUID inst = UUID.randomUUID();

        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .delete("/api/me/institutions/{id}", inst).with(student()))
                .andExpect(status().isOk());

        verify(userInstitutionsUseCase).remove(STUDENT_ID, inst);
    }
}
