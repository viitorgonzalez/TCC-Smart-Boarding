package com.smartboarding.smartboarding_api.infrastructure.web.user;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.FindUserUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.in.ManageUserStatusUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UserController.class)
@org.springframework.context.annotation.Import(UserControllerTest.FixedClock.class)
class UserControllerTest extends WebMvcTestSupport {

    /// O recorte de 6 meses do historico usa o relogio do sistema; fixo aqui
    /// pra o teste nao depender da data em que roda.
    @org.springframework.boot.test.context.TestConfiguration
    static class FixedClock {
        @org.springframework.context.annotation.Bean
        java.time.Clock clock() {
            return java.time.Clock.fixed(
                    java.time.LocalDateTime.of(2026, 9, 12, 10, 0)
                            .toInstant(java.time.ZoneOffset.UTC),
                    java.time.ZoneOffset.UTC);
        }
    }

    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");
    private static final UUID INSTITUTION_ID = UUID.fromString("cccccccc-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean FindUserUseCase findUserUseCase;
    @MockitoBean InstitutionRepositoryPort institutionRepository;
    @MockitoBean ManageUserStatusUseCase manageUserStatusUseCase;
    @MockitoBean UserRepositoryPort userRepository;
    @MockitoBean ListEntryRepositoryPort listEntryRepository;

    private User aluno;

    @BeforeEach
    void setUp() {
        aluno = User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br")
                .fullName("Fernanda Lima").course("Engenharia").role(Role.STUDENT)
                .phone("37999990000").address("Rua X, 123")
                .birthDate(java.time.LocalDate.of(2004, 5, 10))
                .password("$2a$10$hashQueNaoPodeVazar")
                .institutionId(INSTITUTION_ID).isActive(true).build();
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara").build()));
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(INSTITUTION_ID).name("Unifor").routeId(ROUTE_ID).build()));
        when(listEntryRepository.findAttendanceSince(any(), any())).thenReturn(List.of());
        when(manageUserStatusUseCase.history(any())).thenReturn(List.of());
    }

    /// /api/users/** é hasRole("ADMIN") — a lista de alunos com e-mail não pode
    /// ficar acessível a um aluno logado.
    @Test
    void alunoNaoAcessaAListagemDeUsuarios() throws Exception {
        mvc.perform(get("/api/users").with(student())).andExpect(status().isForbidden());

        verify(findUserUseCase, never()).findAll();
    }

    @Test
    void semTokenDevolve401() throws Exception {
        mvc.perform(get("/api/users")).andExpect(status().isUnauthorized());
    }

    @Test
    void semRouteIdListaTodos() throws Exception {
        when(findUserUseCase.findAll()).thenReturn(List.of(aluno));

        mvc.perform(get("/api/users").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].fullName").value("Fernanda Lima"))
                .andExpect(jsonPath("$.data[0].institution").value("Unifor"));

        verify(findUserUseCase, never()).findByRoute(any());
    }

    @Test
    void comRouteIdFiltraPelaRota() throws Exception {
        when(findUserUseCase.findByRoute(ROUTE_ID)).thenReturn(List.of(aluno));

        mvc.perform(get("/api/users").param("routeId", ROUTE_ID.toString()).with(admin()))
                .andExpect(status().isOk());

        verify(findUserUseCase).findByRoute(ROUTE_ID);
        verify(findUserUseCase, never()).findAll();
    }

    @Test
    void usuarioInexistenteDevolve404() throws Exception {
        when(findUserUseCase.findById(any())).thenThrow(new NotFoundException("Usuário não encontrado"));

        mvc.perform(get("/api/users/{id}", STUDENT_ID).with(admin()))
                .andExpect(status().isNotFound());
    }

    /// O admin precisa do contato pra falar com o aluno e do nascimento pra
    /// conferir a matrícula -- a ficha e completa de proposito.
    @Test
    void perfilCarregaAFichaCompletaDoAluno() throws Exception {
        when(findUserUseCase.findById(STUDENT_ID)).thenReturn(aluno);

        mvc.perform(get("/api/users/{id}/profile", STUDENT_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("Fernanda Lima"))
                .andExpect(jsonPath("$.data.email").value("fernanda@edu.unifor.br"))
                .andExpect(jsonPath("$.data.phone").value("37999990000"))
                .andExpect(jsonPath("$.data.address").value("Rua X, 123"))
                .andExpect(jsonPath("$.data.birthDate").value("2004-05-10"))
                .andExpect(jsonPath("$.data.course").value("Engenharia"))
                .andExpect(jsonPath("$.data.institution").value("Unifor"));
    }

    /// A senha (hash incluso) nao tem uso de leitura nenhum. Ela nunca pode
    /// aparecer na resposta, por mais completa que a ficha seja.
    @Test
    void perfilNuncaCarregaSenha() throws Exception {
        when(findUserUseCase.findById(STUDENT_ID)).thenReturn(aluno);

        var body = mvc.perform(get("/api/users/{id}/profile", STUDENT_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.password").doesNotExist())
                .andExpect(jsonPath("$.data.passwordHash").doesNotExist())
                .andReturn().getResponse().getContentAsString();

        org.assertj.core.api.Assertions.assertThat(body)
                .doesNotContain("$2a$").doesNotContain("password");
    }

    /// A ficha e do admin. Aluno logado nao pode ler o contato de colega.
    @Test
    void alunoNaoLeAFichaDeNinguem() throws Exception {
        mvc.perform(get("/api/users/{id}/profile", STUDENT_ID).with(student()))
                .andExpect(status().isForbidden());

        mvc.perform(get("/api/users/{id}/profile", STUDENT_ID))
                .andExpect(status().isUnauthorized());
    }

    /// Desativar aluno registra qual admin fez — o id sai do token, não do corpo.
    @Test
    void desativarRegistraOAdminDoToken() throws Exception {
        when(manageUserStatusUseCase.setActive(STUDENT_ID, false, ADMIN_ID)).thenReturn(aluno);

        mvc.perform(patch("/api/users/{id}/status", STUDENT_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"active":false}"""))
                .andExpect(status().isOk());

        verify(manageUserStatusUseCase).setActive(STUDENT_ID, false, ADMIN_ID);
    }

    @Test
    void alunoNaoPodeMudarOProprioStatus() throws Exception {
        mvc.perform(patch("/api/users/{id}/status", STUDENT_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"active":true}"""))
                .andExpect(status().isForbidden());

        verify(manageUserStatusUseCase, never()).setActive(any(), anyBoolean(), any());
    }

    @Test
    void buscarPorIdResolveONomeDaInstituicao() throws Exception {
        when(findUserUseCase.findById(STUDENT_ID)).thenReturn(aluno);

        mvc.perform(get("/api/users/{id}", STUDENT_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("Fernanda Lima"))
                .andExpect(jsonPath("$.data.institution").value("Unifor"));
    }

    /// O card mostra em que dias o aluno embarcou. Dois embarques no mesmo dia
    /// (ida e volta) contam como um.
    @Test
    void presencaVemSemDataRepetida() throws Exception {
        var dia = java.time.LocalDate.of(2026, 9, 8);
        var outroDia = java.time.LocalDate.of(2026, 9, 9);
        when(findUserUseCase.findById(STUDENT_ID)).thenReturn(aluno);
        when(listEntryRepository.findAttendanceSince(any(), any())).thenReturn(List.of(
                entradaEm(dia), entradaEm(dia), entradaEm(outroDia)));

        mvc.perform(get("/api/users/{id}/profile", STUDENT_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.recentAttendance.length()").value(2));
    }

    private com.smartboarding.smartboarding_api.domain.list.entity.ListEntry entradaEm(
            java.time.LocalDate date) {
        return com.smartboarding.smartboarding_api.domain.list.entity.ListEntry.builder()
                .dailyList(com.smartboarding.smartboarding_api.domain.list.entity.DailyList.builder()
                        .date(date).build())
                .build();
    }

    /// O log tem que dizer QUEM ativou ou desativou, não só que mudou.
    @Test
    void historicoTrazONomeDoAdminQueMudouOStatus() throws Exception {
        when(findUserUseCase.findById(STUDENT_ID)).thenReturn(aluno);
        when(userRepository.findById(ADMIN_ID)).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).fullName("Naiara Souza").build()));
        when(manageUserStatusUseCase.history(STUDENT_ID)).thenReturn(List.of(
                com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog.builder()
                        .userId(STUDENT_ID).adminId(ADMIN_ID)
                        .action(com.smartboarding.smartboarding_api.domain.user.entity
                                .UserStatusAction.DEACTIVATED)
                        .createdAt(java.time.LocalDateTime.of(2026, 9, 9, 10, 30))
                        .build()));

        mvc.perform(get("/api/users/{id}/profile", STUDENT_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.statusHistory[0].action").value("DEACTIVATED"))
                .andExpect(jsonPath("$.data.statusHistory[0].adminName").value("Naiara Souza"))
                .andExpect(jsonPath("$.data.statusHistory[0].at").exists());
    }

    /// Admin apagado depois da mudança não pode derrubar o card — o registro do
    /// que aconteceu continua valendo mesmo sem o nome.
    @Test
    void adminApagadoDeixaOHistoricoSemNomeMasIntacto() throws Exception {
        when(findUserUseCase.findById(STUDENT_ID)).thenReturn(aluno);
        when(userRepository.findById(ADMIN_ID)).thenReturn(Optional.empty());
        when(manageUserStatusUseCase.history(STUDENT_ID)).thenReturn(List.of(
                com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog.builder()
                        .userId(STUDENT_ID).adminId(ADMIN_ID)
                        .action(com.smartboarding.smartboarding_api.domain.user.entity
                                .UserStatusAction.ACTIVATED)
                        .createdAt(java.time.LocalDateTime.of(2026, 9, 9, 10, 30))
                        .build()));

        mvc.perform(get("/api/users/{id}/profile", STUDENT_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.statusHistory[0].action").value("ACTIVATED"))
                .andExpect(jsonPath("$.data.statusHistory[0].adminName").doesNotExist());
    }

    @Test
    void promoverDevolve200EChamaOUseCaseComOAdminDoToken() throws Exception {
        when(manageUserStatusUseCase.setRole(any(), any(), any())).thenAnswer(i ->
                com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                        .id(i.getArgument(0)).fullName("Ana Oliveira").isActive(true)
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                        .build());

        mvc.perform(patch("/api/users/{id}/role", STUDENT_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"role":"ADMIN"}"""))
                .andExpect(status().isOk());

        verify(manageUserStatusUseCase).setRole(STUDENT_ID,
                com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN, ADMIN_ID);
    }

    /// Aluno mexendo em papel seria escalada de privilegio pela porta da frente.
    @Test
    void alunoNaoPodeMexerEmPapel() throws Exception {
        mvc.perform(patch("/api/users/{id}/role", STUDENT_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"role":"ADMIN"}"""))
                .andExpect(status().isForbidden());

        verify(manageUserStatusUseCase, org.mockito.Mockito.never())
                .setRole(any(), any(), any());
    }

    @Test
    void papelInvalidoERecusadoAntesDoUseCase() throws Exception {
        mvc.perform(patch("/api/users/{id}/role", STUDENT_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"role":"SUPERUSER"}"""))
                .andExpect(status().isBadRequest());

        verify(manageUserStatusUseCase, org.mockito.Mockito.never())
                .setRole(any(), any(), any());
    }

    /// A folha do usuário chama isto pra saber se está olhando o último admin.
    /// Antes ela baixava /api/users inteiro e contava no cliente — o contato de
    /// toda a base no fio pra chegar num número.
    @Test
    void contagemDeAdminsDevolveSoONumero() throws Exception {
        when(findUserUseCase.countAdmins()).thenReturn(2L);

        mvc.perform(get("/api/users/admins/count").with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(2));

        verify(findUserUseCase, never()).findAll();
    }

    @Test
    void alunoNaoLeAContagemDeAdmins() throws Exception {
        mvc.perform(get("/api/users/admins/count").with(student()))
                .andExpect(status().isForbidden());

        verify(findUserUseCase, never()).countAdmins();
    }

    // ─── Revogação imediata: a autoridade vem do banco, não da claim ─────────
    //
    // A claim "scope" é carimbada no login e vale 1h. Enquanto ela mandava, o
    // admin rebaixado continuava admin até o token expirar — e nesse intervalo
    // chamava PATCH /api/users/{ele}/role e se promovia de volta. Os testes
    // abaixo mandam Bearer de verdade de propósito: é o único caminho que passa
    // pelo converter do SecurityConfig (os post-processors põem authority
    // direto no contexto e nunca o exercitam).

    private static Jwt tokenComScopeAdmin(String email) {
        return tokenComScope(email, "ADMIN");
    }

    @Test
    void rebaixadoNoBancoNaoSePromoveDeVoltaComOTokenAntigo() throws Exception {
        when(jwtDecoder.decode(BEARER_REAL))
                .thenReturn(tokenComScopeAdmin("naiara@admin.com"));
        when(userDetailsService.loadUserByUsername("naiara@admin.com")).thenReturn(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara")
                        .role(Role.STUDENT).isActive(true).build());

        mvc.perform(comBearerReal(patch("/api/users/{id}/role", ADMIN_ID))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"role":"ADMIN"}"""))
                .andExpect(status().isForbidden());

        verify(manageUserStatusUseCase, never()).setRole(any(), any(), any());
    }

    /// 401, não 403: conta desativada não fica autenticada sem papel — ela para
    /// de autenticar. A diferença não é cosmética. Autoridade vazia ainda
    /// satisfaz `anyRequest().authenticated()`, e por isso o 403 aqui só
    /// aparecia porque /api/users exige ADMIN; nos endpoints que pedem apenas
    /// autenticação a mesma conta seguia passando. Recusando no converter, o
    /// filtro do resource server encerra antes da autorização, pra qualquer rota.
    @Test
    void contaDesativadaPerdeOAcessoAntesDoTokenExpirar() throws Exception {
        when(jwtDecoder.decode(BEARER_REAL))
                .thenReturn(tokenComScopeAdmin("naiara@admin.com"));
        when(userDetailsService.loadUserByUsername("naiara@admin.com")).thenReturn(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara")
                        .role(Role.ADMIN).isActive(false).build());

        mvc.perform(comBearerReal(get("/api/users"))).andExpect(status().isUnauthorized());

        verify(findUserUseCase, never()).findAll();
    }

    @Test
    void contaApagadaNaoAutenticaMais() throws Exception {
        when(jwtDecoder.decode(BEARER_REAL))
                .thenReturn(tokenComScopeAdmin("fantasma@admin.com"));
        when(userDetailsService.loadUserByUsername("fantasma@admin.com")).thenThrow(
                new org.springframework.security.core.userdetails.UsernameNotFoundException(
                        "Usuário não encontrado: fantasma@admin.com"));

        mvc.perform(comBearerReal(get("/api/users"))).andExpect(status().isUnauthorized());

        verify(findUserUseCase, never()).findAll();
    }

    /// Banco fora não pode virar 500 cru em toda requisição autenticada — nem
    /// virar acesso liberado. 503 e não 401 de propósito: o app manda o usuário
    /// refazer login no 401, e refazer login com o banco fora não resolve nada.
    @Test
    void falhaDeBancoFechaOAcessoSemVirar500() throws Exception {
        when(jwtDecoder.decode(BEARER_REAL))
                .thenReturn(tokenComScopeAdmin("naiara@admin.com"));
        when(userDetailsService.loadUserByUsername("naiara@admin.com")).thenThrow(
                new org.springframework.dao.QueryTimeoutException("pool esgotado"));

        mvc.perform(comBearerReal(get("/api/users")))
                .andExpect(status().isServiceUnavailable());

        verify(findUserUseCase, never()).findAll();
    }

    /// O contraponto dos três acima: o mesmo caminho de Bearer real, com o papel
    /// do banco batendo, continua passando. Sem ele, um converter que negasse
    /// tudo deixaria a suíte verde.
    @Test
    void adminDeVerdadeNoBancoSegueEntrandoPeloTokenReal() throws Exception {
        when(jwtDecoder.decode(BEARER_REAL))
                .thenReturn(tokenComScopeAdmin("naiara@admin.com"));
        when(userDetailsService.loadUserByUsername("naiara@admin.com")).thenReturn(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara")
                        .role(Role.ADMIN).isActive(true).build());
        when(findUserUseCase.findAll()).thenReturn(List.of(aluno));

        mvc.perform(comBearerReal(get("/api/users"))).andExpect(status().isOk());
    }
}
