package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.application.user.AuthToken;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.RequestPasswordResetUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.ResetPasswordUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.LoginUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.RegisterUseCase;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
class AuthControllerTest extends WebMvcTestSupport {

    @Autowired MockMvc mvc;

    @MockitoBean LoginUseCase loginUseCase;
    @MockitoBean RegisterUseCase registerUseCase;
    @MockitoBean RequestPasswordResetUseCase requestPasswordResetUseCase;
    @MockitoBean ResetPasswordUseCase resetPasswordUseCase;

    @Test
    void loginValidoDevolve200ComTokenNomeEPapel() throws Exception {
        when(loginUseCase.execute("fernanda@edu.unifor.br", "sb@2026"))
                .thenReturn(new AuthToken("jwt-assinado", "Fernanda Lima", "STUDENT"));

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","password":"sb@2026"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").value("jwt-assinado"))
                .andExpect(jsonPath("$.data.fullName").value("Fernanda Lima"))
                .andExpect(jsonPath("$.data.role").value("STUDENT"));
    }

    @Test
    void credencialInvalidaDevolve401() throws Exception {
        when(loginUseCase.execute(anyString(), anyString()))
                .thenThrow(new UnauthorizedException("Credenciais inválidas"));

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","password":"errada"}"""))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Credenciais inválidas"));
    }

    @Test
    void corpoInvalidoDevolve400SemChegarNoUseCase() throws Exception {
        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"nao-e-email","password":""}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        verify(loginUseCase, never()).execute(anyString(), anyString());
    }

    /// RN22: a resposta é idêntica exista ou não a conta. Se o corpo variasse,
    /// o endpoint viraria um confirmador de e-mails cadastrados.
    @Test
    void forgotPasswordRespondeIgualParaContaExistenteEInexistente() throws Exception {
        var comConta = mvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br"}"""))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        doThrow(new RuntimeException("não deveria vazar"))
                .when(requestPasswordResetUseCase).request("ninguem@edu.unifor.br");

        var semConta = mvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"ninguem@edu.unifor.br"}"""))
                .andReturn().getResponse().getContentAsString();

        // O use case decide se manda e-mail; o controller nunca diferencia os dois.
        org.assertj.core.api.Assertions.assertThat(comConta).contains("success");
        org.assertj.core.api.Assertions.assertThat(semConta).doesNotContain("não encontrado");
    }

    @Test
    void resetPasswordRepassaEmailCodigoESenhaNova() throws Exception {
        mvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","code":"123456","newPassword":"novaSenha1"}"""))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("success")));

        verify(resetPasswordUseCase).reset("fernanda@edu.unifor.br", "123456", "novaSenha1");
    }

    @Test
    void codigoExpiradoDevolve400ComOCodigoDoErro() throws Exception {
        doThrow(new BadRequestException("CODE_EXPIRED", "Código expirado."))
                .when(resetPasswordUseCase).reset(anyString(), anyString(), anyString());

        mvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","code":"000000","newPassword":"novaSenha1"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CODE_EXPIRED"));
    }

    /// /api/auth/register é hasRole("ADMIN") no SecurityConfig — aluno logado não
    /// pode criar conta de admin.
    @Test
    void registerSemAdminEBloqueado() throws Exception {
        mvc.perform(post("/api/auth/register").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"novo@admin.com","fullName":"Novo Admin","password":"senha123","role":"ADMIN"}"""))
                .andExpect(status().isForbidden());

        verify(registerUseCase, never()).execute(any(), anyString());
    }

    @Test
    void registerComoAdminDevolve201() throws Exception {
        when(registerUseCase.execute(any(), eq("senha123"))).thenAnswer(inv ->
                com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                        .id(java.util.UUID.randomUUID()).email("novo@admin.com")
                        .fullName("Novo Admin")
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                        .build());

        mvc.perform(post("/api/auth/register").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"novo@admin.com","fullName":"Novo Admin","password":"senha123","role":"ADMIN"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.email").value("novo@admin.com"));
    }
}
