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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProfileController.class)
class ProfileControllerTest extends WebMvcTestSupport {

    @Autowired MockMvc mvc;

    @MockitoBean ManageProfileUpdateUseCase useCase;
    @MockitoBean UserRepositoryPort userRepository;
    @MockitoBean com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase
            userInstitutionsUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.SetLocalPasswordUseCase
            setLocalPasswordUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.ChangePasswordUseCase
            changePasswordUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.emailchange.port.in.RequestEmailChangeUseCase
            requestEmailChangeUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.emailchange.port.in.ConfirmEmailChangeUseCase
            confirmEmailChangeUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.UpdateAddressUseCase
            updateAddressUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.UpdateOwnProfileUseCase
            updateOwnProfileUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort
            institutionRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(
                User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br")
                        .fullName("Fernanda Lima")
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                        .googleId("google-123").build()));
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara")
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                        .password("$2a$10$hash").build()));
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
    void filaTrazOValorAtualAoLadoDoPedido() throws Exception {
        var pedido = ProfileUpdateRequest.builder()
                .id(UUID.randomUUID()).userId(STUDENT_ID)
                .phone("37988887777").status(ProfileUpdateStatus.PENDING).build();
        when(useCase.listPending()).thenReturn(List.of(pedido));
        when(userRepository.findAll()).thenReturn(List.of(
                User.builder().id(STUDENT_ID).fullName("Fernanda Lima")
                        .phone("37911112222").build()));

        mvc.perform(get("/api/profile-requests").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].phone").value("37988887777"))
                .andExpect(jsonPath("$.data[0].before.phone").value("37911112222"));
    }

    @Test
    void adminAprovaRegistrandoQuemDecidiu() throws Exception {
        UUID id = UUID.randomUUID();

        mvc.perform(post("/api/profile-requests/{id}/approve", id).with(admin()))
                .andExpect(status().isOk());

        verify(useCase).approve(id, ADMIN_ID);
    }

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

    @Test
    void definirSenhaUsaOUsuarioDoToken() throws Exception {
        mvc.perform(post("/api/me/password").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"password":"minhaSenha1"}"""))
                .andExpect(status().isOk());

        verify(setLocalPasswordUseCase).setPassword(STUDENT_ID, "minhaSenha1");
    }

    @Test
    void definirSenhaExigeToken() throws Exception {
        mvc.perform(post("/api/me/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"password":"minhaSenha1"}"""))
                .andExpect(status().isUnauthorized());

        verify(setLocalPasswordUseCase, never()).setPassword(any(), anyString());
    }

    @Test
    void senhaCurtaERecusadaAntesDoUseCase() throws Exception {
        mvc.perform(post("/api/me/password").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"password":"123"}"""))
                .andExpect(status().isBadRequest());

        verify(setLocalPasswordUseCase, never()).setPassword(any(), anyString());
    }

    @Test
    void quemJaTemSenhaRecebe409() throws Exception {
        org.mockito.Mockito.doThrow(new com.smartboarding.smartboarding_api.shared.exception
                        .ConflictException("PASSWORD_ALREADY_SET", "Você já tem senha."))
                .when(setLocalPasswordUseCase).setPassword(any(), anyString());

        mvc.perform(post("/api/me/password").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"password":"minhaSenha1"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("PASSWORD_ALREADY_SET"));
    }

    @Test
    void meInformaPorOndeAContaEntra() throws Exception {
        mvc.perform(get("/api/me").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.hasPassword").value(false))
                .andExpect(jsonPath("$.data.hasGoogle").value(true))
                .andExpect(jsonPath("$.data.role").value("STUDENT"));

        mvc.perform(get("/api/me").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.hasPassword").value(true))
                .andExpect(jsonPath("$.data.hasGoogle").value(false));
    }

    @Test
    void meExigeAutenticacao() throws Exception {
        mvc.perform(get("/api/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void meNaoExpoeOHashDaSenha() throws Exception {
        String corpo = mvc.perform(get("/api/me").with(admin()))
                .andReturn().getResponse().getContentAsString();

        org.assertj.core.api.Assertions.assertThat(corpo).doesNotContain("$2a$10$hash");
    }

    @Test
    void pedirTrocaDeEmailUsaOUsuarioDoToken() throws Exception {
        mvc.perform(post("/api/me/email/request").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newEmail":"novo@edu.unifor.br"}"""))
                .andExpect(status().isOk());

        verify(requestEmailChangeUseCase).request(STUDENT_ID, "novo@edu.unifor.br");
    }

    @Test
    void pedirTrocaDeEmailExigeToken() throws Exception {
        mvc.perform(post("/api/me/email/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newEmail":"novo@edu.unifor.br"}"""))
                .andExpect(status().isUnauthorized());

        verify(requestEmailChangeUseCase, never()).request(any(), any());
    }

    @Test
    void pedirTrocaComEmailInvalidoERecusadoAntesDoUseCase() throws Exception {
        mvc.perform(post("/api/me/email/request").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newEmail":"nao-e-email"}"""))
                .andExpect(status().isBadRequest());

        verify(requestEmailChangeUseCase, never()).request(any(), any());
    }

    @Test
    void confirmarTrocaDeEmailUsaOUsuarioDoToken() throws Exception {
        mvc.perform(post("/api/me/email/confirm").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"123456"}"""))
                .andExpect(status().isOk());

        verify(confirmEmailChangeUseCase).confirm(STUDENT_ID, "123456");
    }

    @Test
    void confirmarComCodigoForaDoFormatoERecusadoAntesDoUseCase() throws Exception {
        mvc.perform(post("/api/me/email/confirm").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"abc"}"""))
                .andExpect(status().isBadRequest());

        verify(confirmEmailChangeUseCase, never()).confirm(any(), any());
    }

    @Test
    void emailJaEmUsoDevolve409() throws Exception {
        org.mockito.Mockito.doThrow(new com.smartboarding.smartboarding_api.shared.exception
                        .ConflictException("EMAIL_ALREADY_EXISTS", "Esse e-mail já está em uso."))
                .when(requestEmailChangeUseCase).request(any(), any());

        mvc.perform(post("/api/me/email/request").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"newEmail":"ocupado@edu.unifor.br"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("EMAIL_ALREADY_EXISTS"));
    }

    private static final String ENDERECO_JSON = """
            {"zipCode":"35570-000","street":"Av. Dr. Arnaldo de Senna",
             "neighborhood":"Água Vermelha","city":"Formiga","state":"MG",
             "streetNumber":"328"}
            """;

    @Test
    void alunoSalvaOProprioEnderecoSemAbrirSolicitacao() throws Exception {
        when(updateAddressUseCase.update(eq(STUDENT_ID), any()))
                .thenAnswer(inv -> inv.getArgument(1));

        mvc.perform(put("/api/me/address").with(student())
                        .contentType(MediaType.APPLICATION_JSON).content(ENDERECO_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.street").value("Av. Dr. Arnaldo de Senna"))
                .andExpect(jsonPath("$.data.complete").value(true));

        verify(useCase, never()).request(any(), any());
    }

    @Test
    void enderecoVaiSempreProDonoDoToken() throws Exception {
        when(updateAddressUseCase.update(any(), any())).thenAnswer(inv -> inv.getArgument(1));

        mvc.perform(put("/api/me/address").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"userId":"%s","zipCode":"35570-000","street":"Rua A",
                                 "neighborhood":"Centro","streetNumber":"1"}
                                """.formatted(ADMIN_ID)))
                .andExpect(status().isOk());

        verify(updateAddressUseCase).update(eq(STUDENT_ID), any());
    }

    @Test
    void enderecoExigeAutenticacao() throws Exception {
        mvc.perform(put("/api/me/address")
                        .contentType(MediaType.APPLICATION_JSON).content(ENDERECO_JSON))
                .andExpect(status().isUnauthorized());

        verify(updateAddressUseCase, never()).update(any(), any());
    }

    @Test
    void meDizOQueFaltaProPerfilEntrarNaLista() throws Exception {
        mvc.perform(get("/api/me").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.missingForList")
                        .value(org.hamcrest.Matchers.containsInAnyOrder(
                                "phone", "address", "institution")));
    }
}
