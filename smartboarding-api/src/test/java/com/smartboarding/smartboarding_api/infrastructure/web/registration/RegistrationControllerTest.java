package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ApproveRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ListPendingRegistrationsUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.RejectRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ResendCodeUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.ValidateTokenUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.in.VerifyInviteCodeUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RegistrationController.class)
class RegistrationControllerTest extends WebMvcTestSupport {

    private static final UUID INSTITUTION_ID = UUID.fromString("cccccccc-0000-0000-0000-000000000001");
    private static final UUID REQUEST_ID = UUID.fromString("ffffffff-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean GenerateInviteUseCase generateInviteUseCase;
    @MockitoBean ValidateTokenUseCase validateTokenUseCase;
    @MockitoBean SubmitRegistrationUseCase submitRegistrationUseCase;
    @MockitoBean ListPendingRegistrationsUseCase listPendingRegistrationsUseCase;
    @MockitoBean ApproveRegistrationUseCase approveRegistrationUseCase;
    @MockitoBean RejectRegistrationUseCase rejectRegistrationUseCase;
    @MockitoBean VerifyInviteCodeUseCase verifyInviteCodeUseCase;
    @MockitoBean ResendCodeUseCase resendCodeUseCase;
    @MockitoBean InstitutionRepositoryPort institutionRepository;

    @BeforeEach
    void setUp() {
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(INSTITUTION_ID).name("Unifor").build()));
        when(listPendingRegistrationsUseCase.listPending()).thenReturn(List.of());
    }

    private RegistrationRequest pedido() {
        return RegistrationRequest.builder().id(REQUEST_ID).email("fernanda@edu.unifor.br")
                .fullName("Fernanda Lima").institutionId(INSTITUTION_ID).course("Engenharia")
                .status(RegistrationStatus.PENDING).build();
    }

    /// RN13: o convite é emitido pelo admin. Se qualquer um pudesse gerar, o
    /// cadastro por convite deixaria de ser por convite.
    @Test
    void gerarConviteEDoAdmin() throws Exception {
        mvc.perform(post("/api/registration/invite")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"invasor@edu.unifor.br"}"""))
                .andExpect(status().isUnauthorized());

        mvc.perform(post("/api/registration/invite").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"invasor@edu.unifor.br"}"""))
                .andExpect(status().isForbidden());

        verify(generateInviteUseCase, never()).generateInvite(anyString());
    }

    @Test
    void adminGeraConviteERecebe201() throws Exception {
        mvc.perform(post("/api/registration/invite").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br"}"""))
                .andExpect(status().isCreated());

        verify(generateInviteUseCase).generateInvite("fernanda@edu.unifor.br");
    }

    @Test
    void conviteParaEmailInvalidoERecusado() throws Exception {
        mvc.perform(post("/api/registration/invite").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"nao-e-email"}"""))
                .andExpect(status().isBadRequest());

        verify(generateInviteUseCase, never()).generateInvite(anyString());
    }

    /// Os passos do convidado são públicos de propósito: ele ainda não tem conta.
    @Test
    void verificarCodigoEPublicoEDevolveOToken() throws Exception {
        when(verifyInviteCodeUseCase.verifyCode("fernanda@edu.unifor.br", "123456"))
                .thenReturn("convite-x1");

        mvc.perform(post("/api/registration/verify-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","code":"123456"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").value("convite-x1"));
    }

    /// O código tem 6 dígitos. Barrar formato errado no controller evita gastar
    /// tentativa do limite de força bruta com entrada que nunca poderia valer.
    @Test
    void codigoForaDoFormatoNemChegaNoUseCase() throws Exception {
        mvc.perform(post("/api/registration/verify-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","code":"12ab"}"""))
                .andExpect(status().isBadRequest());

        verify(verifyInviteCodeUseCase, never()).verifyCode(anyString(), anyString());
    }

    @Test
    void codigoErradoDevolve400ComOCodigoDoErro() throws Exception {
        when(verifyInviteCodeUseCase.verifyCode(anyString(), anyString()))
                .thenThrow(new BadRequestException("INVALID_CODE", "Código inválido."));

        mvc.perform(post("/api/registration/verify-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","code":"000000"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_CODE"));
    }

    @Test
    void reenviarCodigoEPublico() throws Exception {
        mvc.perform(post("/api/registration/resend-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br"}"""))
                .andExpect(status().isOk());

        verify(resendCodeUseCase).resendCode("fernanda@edu.unifor.br");
    }

    @Test
    void consultarConvitePeloTokenEPublico() throws Exception {
        when(validateTokenUseCase.validateToken("convite-x1")).thenReturn(pedido());

        mvc.perform(get("/api/registration/invite/{token}", "convite-x1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.email").value("fernanda@edu.unifor.br"))
                .andExpect(jsonPath("$.data.status").value("PENDING"));
    }

    @Test
    void enviarCadastroRepassaTodosOsDados() throws Exception {
        mvc.perform(post("/api/registration/{token}/submit", "convite-x1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda Lima","password":"sb@2026",\
                                "institutionId":"cccccccc-0000-0000-0000-000000000001",\
                                "course":"Engenharia","phone":"37999990000"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SUBMITTED"));

        var captor = org.mockito.ArgumentCaptor.forClass(SubmitRegistrationUseCase.SubmitData.class);
        verify(submitRegistrationUseCase).submitRegistration(
                org.mockito.ArgumentMatchers.eq("convite-x1"), captor.capture());
        org.assertj.core.api.Assertions.assertThat(captor.getValue().fullName())
                .isEqualTo("Fernanda Lima");
        org.assertj.core.api.Assertions.assertThat(captor.getValue().institutionId())
                .isEqualTo(INSTITUTION_ID);
    }

    /// RN10: senha com menos de 6 caracteres é barrada antes de virar hash.
    @Test
    void senhaCurtaERecusada() throws Exception {
        mvc.perform(post("/api/registration/{token}/submit", "convite-x1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda Lima","password":"123",\
                                "institutionId":"cccccccc-0000-0000-0000-000000000001"}"""))
                .andExpect(status().isBadRequest());

        verify(submitRegistrationUseCase, never()).submitRegistration(anyString(), any());
    }

    @Test
    void cadastroSemInstituicaoERecusado() throws Exception {
        mvc.perform(post("/api/registration/{token}/submit", "convite-x1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda Lima","password":"sb@2026"}"""))
                .andExpect(status().isBadRequest());

        verify(submitRegistrationUseCase, never()).submitRegistration(anyString(), any());
    }

    /// RN14: a fila de aprovação e as decisões são do admin.
    @Test
    void filaEAprovacaoSaoDoAdmin() throws Exception {
        mvc.perform(get("/api/registration/pending").with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/registration/{id}/approve", REQUEST_ID).with(student()))
                .andExpect(status().isForbidden());

        verify(listPendingRegistrationsUseCase, never()).listPending();
        verify(approveRegistrationUseCase, never()).approve(any());
    }

    @Test
    void filaTrazONomeDaInstituicaoResolvido() throws Exception {
        when(listPendingRegistrationsUseCase.listPending()).thenReturn(List.of(pedido()));

        mvc.perform(get("/api/registration/pending").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].institutionName").value("Unifor"))
                .andExpect(jsonPath("$.data[0].email").value("fernanda@edu.unifor.br"));
    }

    @Test
    void adminAprovaCadastro() throws Exception {
        mvc.perform(post("/api/registration/{id}/approve", REQUEST_ID).with(admin()))
                .andExpect(status().isOk());

        verify(approveRegistrationUseCase).approve(REQUEST_ID);
    }

    /// Recusar sem motivo não passa: o motivo é o que o candidato vê pra saber o
    /// que corrigir.
    @Test
    void recusarSemMotivoERecusado() throws Exception {
        mvc.perform(post("/api/registration/{id}/reject", REQUEST_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":""}"""))
                .andExpect(status().isBadRequest());

        verify(rejectRegistrationUseCase, never()).reject(any(), anyString());
    }

    @Test
    void adminRecusaComMotivo() throws Exception {
        mvc.perform(post("/api/registration/{id}/reject", REQUEST_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"Instituição não atendida por essa rota"}"""))
                .andExpect(status().isOk());

        verify(rejectRegistrationUseCase).reject(REQUEST_ID, "Instituição não atendida por essa rota");
    }
}
