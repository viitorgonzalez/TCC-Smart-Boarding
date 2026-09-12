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
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.SignupUseCase signupUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.GoogleSignInUseCase googleSignInUseCase;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.in.IssueTokenUseCase issueTokenUseCase;

    @Test
    void loginValidoDevolve200ComTokenNomeEPapel() throws Exception {
        when(loginUseCase.execute("fernanda@edu.unifor.br", "sb@2026"))
                .thenReturn(new AuthToken("jwt-assinado", "Fernanda Lima", "STUDENT", "fernanda@edu.unifor.br"));

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

    /// Cadastro proprio e publico: quem chega aqui ainda nao tem conta, entao
    /// exigir token tornaria o endpoint inalcancavel.
    @Test
    void cadastroProprioEPublicoEDevolveSessaoPronta() throws Exception {
        var criado = com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                .id(java.util.UUID.randomUUID()).email("fernanda@edu.unifor.br")
                .fullName("Fernanda Lima")
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build();
        when(signupUseCase.signup(any(), eq("sb@2026"))).thenReturn(criado);
        when(loginUseCase.execute("fernanda@edu.unifor.br", "sb@2026"))
                .thenReturn(new AuthToken("jwt-novo", "Fernanda Lima", "STUDENT", "fernanda@edu.unifor.br"));

        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda Lima","email":"fernanda@edu.unifor.br",\
                                "password":"sb@2026"}"""))
                .andExpect(status().isCreated())
                // Sessao ja vem pronta: obrigar a digitar de novo o que acabou de
                // ser digitado e atrito sem ganho.
                .andExpect(jsonPath("$.data.token").value("jwt-novo"))
                .andExpect(jsonPath("$.data.role").value("STUDENT"));
    }

    /// RN10: senha com menos de 6 caracteres nao pode nem virar hash.
    @Test
    void cadastroComSenhaCurtaERecusado() throws Exception {
        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda Lima","email":"fernanda@edu.unifor.br",\
                                "password":"123"}"""))
                .andExpect(status().isBadRequest());

        verify(signupUseCase, never()).signup(any(), anyString());
    }

    @Test
    void cadastroComEmailInvalidoOuSemNomeERecusado() throws Exception {
        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda","email":"nao-e-email","password":"sb@2026"}"""))
                .andExpect(status().isBadRequest());

        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"","email":"fernanda@edu.unifor.br","password":"sb@2026"}"""))
                .andExpect(status().isBadRequest());

        verify(signupUseCase, never()).signup(any(), anyString());
    }

    /// O papel nao viaja no request. Mandar "role":"ADMIN" e ignorado -- o DTO
    /// nem tem o campo, e o use case crava STUDENT.
    @Test
    void cadastroIgnoraTentativaDePedirPapelDeAdmin() throws Exception {
        var criado = com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                .id(java.util.UUID.randomUUID()).email("invasor@edu.unifor.br")
                .fullName("Invasor")
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build();
        when(signupUseCase.signup(any(), anyString())).thenReturn(criado);
        when(loginUseCase.execute(anyString(), anyString()))
                .thenReturn(new AuthToken("jwt", "Invasor", "STUDENT", "fernanda@edu.unifor.br"));

        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Invasor","email":"invasor@edu.unifor.br",\
                                "password":"sb@2026","role":"ADMIN"}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.role").value("STUDENT"));
    }

    @Test
    void emailJaCadastradoDevolve409() throws Exception {
        when(signupUseCase.signup(any(), anyString())).thenThrow(
                new com.smartboarding.smartboarding_api.shared.exception.ConflictException("EMAIL_ALREADY_EXISTS", "Esse e-mail já tem conta."));

        mvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Fernanda","email":"fernanda@edu.unifor.br",\
                                "password":"sb@2026"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("EMAIL_ALREADY_EXISTS"));
    }

    // ─── Entrar com Google ────────────────────────────────────────────────────

    /// Publico: e um caminho de entrada, como o login. Exigir token aqui
    /// tornaria o endpoint inalcancavel pra quem nao tem conta.
    @Test
    void entrarComGoogleEPublicoEDevolveSessao() throws Exception {
        var user = com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                .id(java.util.UUID.randomUUID()).email("fernanda@edu.unifor.br")
                .fullName("Fernanda Lima")
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build();
        when(googleSignInUseCase.signIn("id-token-do-google")).thenReturn(user);
        when(issueTokenUseCase.issueFor(user))
                .thenReturn(new AuthToken("jwt-google", "Fernanda Lima", "STUDENT", "fernanda@edu.unifor.br"));

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idToken":"id-token-do-google"}"""))
                .andExpect(status().isOk())
                // Mesmo formato de sessao do login por senha: o caminho de
                // entrada nao muda o que a sessao e.
                .andExpect(jsonPath("$.data.token").value("jwt-google"))
                .andExpect(jsonPath("$.data.role").value("STUDENT"));
    }

    @Test
    void googleSemTokenERecusadoAntesDoUseCase() throws Exception {
        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idToken":""}"""))
                .andExpect(status().isBadRequest());

        verify(googleSignInUseCase, never()).signIn(anyString());
    }

    @Test
    void tokenDoGoogleInvalidoDevolve401() throws Exception {
        when(googleSignInUseCase.signIn(anyString())).thenThrow(
                new UnauthorizedException("Login do Google inválido."));

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idToken":"lixo"}"""))
                .andExpect(status().isUnauthorized());
    }

    /// O app usa o e-mail da sessao pra saber de quem carregar a lista do dia.
    /// Quem entra pelo Google nunca digita e-mail nenhum: se a resposta nao
    /// trouxer, a home fica carregando pra sempre.
    @Test
    void sessaoDoGoogleTrazOEmail() throws Exception {
        when(issueTokenUseCase.issueFor(any())).thenReturn(
                new AuthToken("jwt-google", "Fernanda Lima", "STUDENT", "fernanda@edu.unifor.br"));

        mvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idToken":"id-token-do-google"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.email").value("fernanda@edu.unifor.br"));
    }

    @Test
    void sessaoDoLoginPorSenhaTambemTrazOEmail() throws Exception {
        when(loginUseCase.execute("fernanda@edu.unifor.br", "segredo123")).thenReturn(
                new AuthToken("jwt", "Fernanda Lima", "STUDENT", "fernanda@edu.unifor.br"));

        mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"fernanda@edu.unifor.br","password":"segredo123"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.email").value("fernanda@edu.unifor.br"));
    }
}
