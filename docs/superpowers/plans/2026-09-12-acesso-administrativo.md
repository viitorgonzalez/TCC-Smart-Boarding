# Acesso administrativo por promoção — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Acabar com a criação de conta admin por outro admin; quem é admin passa a ser concedido sobre uma conta que a própria pessoa criou.

**Architecture:** `POST /api/auth/register` sai inteiro. Entra `PATCH /api/users/{id}/role`, com quatro travas e registro no `user_status_log` que já existe. O primeiro admin de um ambiente novo vem de `BOOTSTRAP_ADMIN_EMAIL`, aplicado no cadastro enquanto o sistema tiver zero admins.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · JPA/Hibernate · JUnit 5 + Mockito + AssertJ · Flutter/Dart 3.11 + Provider + Dio

**Spec:** [`../specs/2026-09-12-acesso-administrativo-design.md`](../specs/2026-09-12-acesso-administrativo-design.md)

## Global Constraints

- Papéis existentes: `Role.ADMIN` e `Role.STUDENT`. Nenhum papel novo.
- **Nenhuma migration**: `user_status_log` já tem `user_id`, `admin_id`, `action VARCHAR(20)`, `created_at`, e `admin_id` é nullable.
- Comentário em código explica **o porquê**, nunca o quê (CLAUDE.md do workspace).
- Nomes de variável, função e comentário em **inglês**; mensagens de erro ao usuário em **PT-BR**.
- Todo teste novo precisa **reprovar antes do fix** — rode e veja falhar antes de implementar.
- Gates: `./mvnw verify` (JaCoCo ≥90% em `application.*`, ≥70% no resto) e `./scripts/coverage-gate.sh` no app.
- Nunca commitar sem o usuário pedir.

---

### Task 1: Regra de promoção e rebaixamento

O coração. Sem endpoint ainda — só a regra, testável isoladamente.

> **Vínculos de rota e instituição não são tocados**, nem na promoção nem no rebaixamento
> (spec, "O que acontece com os vínculos"). Isso não vira teste porque é garantido pela
> estrutura: `UserStatusUseCaseImpl` não recebe os repositórios de `route_members` nem de
> `user_institutions`, então não tem como mexer neles. Se alguém adicionar essas dependências
> aqui, é sinal de que a decisão está sendo revertida sem passar pela spec.

**Files:**
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/user/entity/UserStatusAction.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/user/port/in/ManageUserStatusUseCase.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/user/port/out/UserRepositoryPort.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/user/UserJpaRepository.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/user/UserRepositoryAdapter.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/user/UserStatusUseCaseImpl.java`
- Test: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/user/UserStatusUseCaseImplTest.java`

**Interfaces:**
- Consumes: `UserRepositoryPort.findById(UUID)`, `.save(User)`; `UserStatusLogRepositoryPort.save(UserStatusLog)`; `Clock`.
- Produces: `ManageUserStatusUseCase.setRole(UUID userId, Role role, UUID adminId) → User`; `UserRepositoryPort.countAdmins() → long`; `UserStatusAction.PROMOTED`, `.DEMOTED`.

- [ ] **Step 1: Escrever os testes que reprovam**

Anexe ao final de `UserStatusUseCaseImplTest.java`, antes do `}` final:

```java
    /// Promover e conceder acesso, nao criar conta: a conta ja existe e e da
    /// pessoa. O log guarda quem concedeu.
    @Test
    void promoverGravaLogComOAdminQueConcedeu() {
        ArgumentCaptor<UserStatusLog> captor = ArgumentCaptor.forClass(UserStatusLog.class);

        User saved = useCase.setRole(STUDENT, Role.ADMIN, ADMIN);

        assertThat(saved.getRole()).isEqualTo(Role.ADMIN);
        verify(logRepository).save(captor.capture());
        assertThat(captor.getValue().getAction()).isEqualTo(UserStatusAction.PROMOTED);
        assertThat(captor.getValue().getAdminId()).isEqualTo(ADMIN);
        assertThat(captor.getValue().getUserId()).isEqualTo(STUDENT);
    }

    /// PATCH role e declaracao de estado, nao acao: repetir tem que dar o mesmo
    /// resultado. Duplo toque e retry de request que deu timeout nao podem virar
    /// erro, e o log nao pode encher de linha duplicada.
    @Test
    void declararOMesmoPapelNaoGeraLogNemErro() {
        when(userRepository.findById(ADMIN)).thenReturn(Optional.of(
                User.builder().id(ADMIN).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));

        User saved = useCase.setRole(ADMIN, Role.ADMIN, STUDENT);

        assertThat(saved.getRole()).isEqualTo(Role.ADMIN);
        verify(logRepository, never()).save(any());
        verify(userRepository, never()).save(any());
    }

    /// Um clique errado tiraria o acesso de quem esta operando, e so outro admin
    /// poderia devolver.
    @Test
    void ninguemRebaixaAPropriaConta() {
        when(userRepository.findById(ADMIN)).thenReturn(Optional.of(
                User.builder().id(ADMIN).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));

        assertThatThrownBy(() -> useCase.setRole(ADMIN, Role.STUDENT, ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("própria conta");
    }

    /// Sem admin nenhum, ninguem promove ninguem de volta: a recuperacao seria
    /// editar o banco a mao. Esta e a trava que impede o sistema de se trancar.
    @Test
    void oUltimoAdminNaoPodeSerRebaixado() {
        UUID outro = UUID.randomUUID();
        when(userRepository.findById(outro)).thenReturn(Optional.of(
                User.builder().id(outro).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));
        when(userRepository.countAdmins()).thenReturn(1L);

        assertThatThrownBy(() -> useCase.setRole(outro, Role.STUDENT, ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("único administrador");
    }

    @Test
    void comOutroAdminORebaixamentoPassa() {
        UUID outro = UUID.randomUUID();
        when(userRepository.findById(outro)).thenReturn(Optional.of(
                User.builder().id(outro).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));
        when(userRepository.countAdmins()).thenReturn(2L);

        assertThat(useCase.setRole(outro, Role.STUDENT, ADMIN).getRole())
                .isEqualTo(Role.STUDENT);
    }

    /// Promover conta desativada produz um admin que nao consegue entrar: a tela
    /// mostra acesso concedido e o login nega.
    @Test
    void contaDesativadaNaoPodeSerPromovida() {
        UUID inativo = UUID.randomUUID();
        when(userRepository.findById(inativo)).thenReturn(Optional.of(
                User.builder().id(inativo).fullName("Ana").isActive(false)
                        .role(Role.STUDENT).build()));

        assertThatThrownBy(() -> useCase.setRole(inativo, Role.ADMIN, ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("desativada");
    }
```

Adicione os imports que faltarem no topo do arquivo:

```java
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=UserStatusUseCaseImplTest
```

Esperado: **erro de compilação** — `setRole` e `countAdmins` não existem. É a falha correta nesta etapa.

- [ ] **Step 3: Ampliar o enum de auditoria**

`UserStatusAction.java` inteiro passa a ser:

```java
package com.smartboarding.smartboarding_api.domain.user.entity;

/// O que um admin fez com uma conta. Papel entra aqui junto de ativacao porque
/// a pergunta que a auditoria responde e a mesma: o que mudou nesta conta, por
/// quem e quando.
public enum UserStatusAction {
    ACTIVATED, DEACTIVATED, PROMOTED, DEMOTED
}
```

- [ ] **Step 4: Declarar `setRole` na porta de entrada**

Em `ManageUserStatusUseCase.java`, adicione dentro da interface:

```java
    /// Concede ou retira o papel administrativo de uma conta que ja existe.
    /// Conta nao e criada aqui -- ela e do usuario; o que se concede e o papel.
    User setRole(UUID userId, Role role, UUID adminId);
```

E o import:

```java
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
```

- [ ] **Step 5: Contar admins no repositório**

Em `UserRepositoryPort.java`, adicione:

```java
    long countAdmins();
```

Em `UserJpaRepository.java`, adicione:

```java
    @Query("SELECT COUNT(u) FROM User u WHERE u.role = 'ADMIN'")
    long countAdmins();
```

Em `UserRepositoryAdapter.java`, adicione a implementação delegando ao JPA:

O campo do adapter chama-se `jpa`:

```java
    @Override
    public long countAdmins() {
        return jpa.countAdmins();
    }
```

- [ ] **Step 6: Implementar a regra**

Em `UserStatusUseCaseImpl.java`, adicione o método:

```java
    @Override
    @Transactional
    public User setRole(UUID userId, Role role, UUID adminId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        // Declaracao de estado, nao acao: repetir e no-op. Sair antes de qualquer
        // trava mantem o retry e o duplo toque inofensivos.
        if (user.getRole() == role) {
            return user;
        }

        if (role == Role.STUDENT) {
            if (userId.equals(adminId)) {
                throw new BadRequestException("CANNOT_DEMOTE_SELF",
                        "Você não pode rebaixar a própria conta.");
            }
            // Sem admin nenhum ninguem promove ninguem de volta -- a saida seria
            // editar o banco a mao.
            if (userRepository.countAdmins() <= 1) {
                throw new BadRequestException("LAST_ADMIN",
                        "Este é o único administrador; promova outro antes de rebaixá-lo.");
            }
        }

        // Promover quem esta desativado cria um admin que nao consegue entrar: a
        // tela mostraria acesso concedido e o login negaria.
        if (role == Role.ADMIN && !user.isActive()) {
            throw new BadRequestException("INACTIVE_ACCOUNT",
                    "Conta desativada não pode ser promovida. Reative antes.");
        }

        user.setRole(role);
        User saved = userRepository.save(user);

        logRepository.save(UserStatusLog.builder()
                .userId(userId)
                .adminId(adminId)
                .action(role == Role.ADMIN ? UserStatusAction.PROMOTED : UserStatusAction.DEMOTED)
                .createdAt(LocalDateTime.now(clock))
                .build());

        log.info("Papel de {} alterado para {} por {}", userId, role, adminId);
        return saved;
    }
```

A classe **não tem logger hoje**. Anote `@Slf4j` (Lombok) nela, junto de `@Service`, e adicione o import:

```java
import lombok.extern.slf4j.Slf4j;
```

- [ ] **Step 7: Rodar e ver passar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=UserStatusUseCaseImplTest
```

Esperado: **todos passam** (os 7 que já existiam + os 6 novos).

- [ ] **Step 8: Provar que os testes seguram a regra**

Comente a trava do último admin no `setRole`, rode de novo e confirme que `oUltimoAdminNaoPodeSerRebaixado` **reprova**. Descomente e confirme que volta a passar. Teste que não reprova sem o fix não protege nada.

- [ ] **Step 9: Commit**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/user \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/user/UserStatusUseCaseImpl.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/user \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/user/UserStatusUseCaseImplTest.java
git commit -m "feat(users): promover e rebaixar conta existente, com travas e auditoria"
```

---

### Task 2: Endpoint `PATCH /api/users/{id}/role`

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user/dto/UpdateUserRoleRequest.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user/UserController.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Test: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/infrastructure/web/user/UserControllerTest.java`

**Interfaces:**
- Consumes: `ManageUserStatusUseCase.setRole(UUID, Role, UUID)` (Task 1); helpers privados `adminId(Authentication)` e `profileOf(User)` que já existem no controller.
- Produces: `PATCH /api/users/{id}/role` aceitando `{"role":"ADMIN"|"STUDENT"}`, devolvendo `StudentProfileResponse`.

- [ ] **Step 1: Escrever os testes que reprovam**

Anexe ao final de `UserControllerTest.java`, antes do `}` final:

```java
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
```

Adicione o import estático que faltar:

```java
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=UserControllerTest
```

Esperado: **404** nos dois primeiros (rota não existe) e falha no terceiro.

- [ ] **Step 3: Criar o DTO**

`UpdateUserRoleRequest.java`:

```java
package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import jakarta.validation.constraints.NotNull;

/// Papel fora do enum e recusado pela desserializacao, antes de chegar na regra.
public record UpdateUserRoleRequest(@NotNull Role role) {}
```

- [ ] **Step 4: Adicionar o endpoint**

Em `UserController.java`, logo após o método `setStatus`:

```java
    /// Concede ou retira acesso administrativo. Não cria conta: a conta já é da
    /// pessoa, e o que muda aqui é só o papel dela.
    @PatchMapping("/{id}/role")
    public ResponseEntity<ApiResponse<StudentProfileResponse>> setRole(
            @PathVariable UUID id,
            @RequestBody @Valid UpdateUserRoleRequest request,
            Authentication auth) {
        User saved = manageUserStatusUseCase.setRole(id, request.role(), adminId(auth));
        return ResponseEntity.ok(ApiResponse.data(profileOf(saved)));
    }
```

Adicione o import do DTO:

```java
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.UpdateUserRoleRequest;
```

> Se o controller já importa o pacote `dto.*`, não precisa.

- [ ] **Step 5: Liberar a rota só pro admin**

Em `SecurityConfig.java`, ao lado da linha de `/api/users/{id}/status`:

```java
                        .requestMatchers(HttpMethod.PATCH, "/api/users/{id}/role").hasRole("ADMIN")
```

- [ ] **Step 6: Rodar e ver passar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=UserControllerTest
```

Esperado: **todos passam**.

- [ ] **Step 7: Commit**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure
git add smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/infrastructure/web/user/UserControllerTest.java
git commit -m "feat(api): endpoint de promocao e rebaixamento, restrito ao admin"
```

---

### Task 3: Matar a criação de conta admin

Só depois que a promoção existe — senão fica um intervalo sem caminho nenhum.

**Files:**
- Delete: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/user/port/in/RegisterUseCase.java`
- Delete: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user/dto/RegisterRequest.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/user/AuthUseCaseImpl.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user/AuthController.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Modify: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/user/AuthUseCaseImplTest.java`
- Modify: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/infrastructure/web/user/AuthControllerTest.java`
- Modify: `smartboarding_app/lib/features/users/services/user_service.dart`
- Modify: `smartboarding_app/lib/features/users/providers/user_provider.dart`

**Interfaces:**
- Consumes: nada novo.
- Produces: `POST /api/auth/register` deixa de existir. `AuthUseCaseImpl` deixa de implementar `RegisterUseCase`.

- [ ] **Step 1: Escrever o teste que prova que o endpoint sumiu**

Em `AuthControllerTest.java`, substitua os testes que exercitam `/api/auth/register` por este único:

```java
    /// Criar conta pra outra pessoa acabou: o admin que criava digitava a senha
    /// inicial de alguem e continuava sabendo entrar. Acesso admin agora e
    /// concessao sobre conta que a propria pessoa criou.
    @Test
    void oEndpointDeCriarAdminNaoExisteMais() throws Exception {
        mvc.perform(post("/api/auth/register").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"novo@admin.com","password":"segredo123","role":"ADMIN","fullName":"Novo"}"""))
                .andExpect(status().isNotFound());
    }
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=AuthControllerTest
```

Esperado: **falha** — hoje responde 201, não 404.

- [ ] **Step 3: Remover do controller**

Em `AuthController.java`: apague o método `register` inteiro, o campo `registerUseCase`, o parâmetro correspondente no construtor e a linha de atribuição, além dos imports de `RegisterUseCase` e `RegisterRequest`.

- [ ] **Step 4: Remover do use case**

Em `AuthUseCaseImpl.java`: apague o método `execute(User, String)` (o de registro, com a trava `ADMIN_ONLY`) e tire `RegisterUseCase` da lista de interfaces implementadas na declaração da classe.

A declaração hoje é:

```java
public class AuthUseCaseImpl implements LoginUseCase, RegisterUseCase, IssueTokenUseCase,
        UserDetailsService {
```

Passa a ser:

```java
public class AuthUseCaseImpl implements LoginUseCase, IssueTokenUseCase, UserDetailsService {
```

- [ ] **Step 5: Apagar os arquivos e a regra de segurança**

```bash
cd smartboarding-api
git rm src/main/java/com/smartboarding/smartboarding_api/domain/user/port/in/RegisterUseCase.java
git rm src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user/dto/RegisterRequest.java
```

Em `SecurityConfig.java`, apague a linha:

```java
                        .requestMatchers(HttpMethod.POST, "/api/auth/register").hasRole("ADMIN")
```

- [ ] **Step 6: Limpar os testes órfãos**

Em `AuthUseCaseImplTest.java`, apague os testes que chamam o `execute` de registro (os que verificam `ADMIN_ONLY` e criação de admin) e o helper `useCase()` se ele ficar sem uso.

- [ ] **Step 7: Remover o código morto do app**

Em `user_service.dart`, apague o método `register`. Em `user_provider.dart`, apague o método `register`. Nenhuma tela chama os dois — confirme antes:

```bash
cd smartboarding_app && grep -rn "\.register(" lib --include=*.dart
```

Esperado: **nenhuma saída**.

- [ ] **Step 8: Rodar tudo**

```bash
cd smartboarding-api && ./mvnw -o verify
cd ../smartboarding_app && flutter analyze && flutter test
```

Esperado: **BUILD SUCCESS**, analyze limpo, testes verdes.

- [ ] **Step 9: Commit**

```bash
git add -A smartboarding-api smartboarding_app/lib
git commit -m "refactor(auth): remove a criacao de conta admin por outro admin"
```

---

### Task 4: Primeiro admin de um ambiente novo

**Files:**
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/user/SignupUseCaseImpl.java`
- Modify: `smartboarding-api/src/main/resources/application.properties`
- Modify: `smartboarding-api/.env.example`
- Test: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/user/SignupUseCaseImplTest.java`

**Interfaces:**
- Consumes: `UserRepositoryPort.countAdmins()` (Task 1).
- Produces: construtor de `SignupUseCaseImpl` ganha um terceiro parâmetro `String bootstrapAdminEmail`.

- [ ] **Step 1: Escrever os testes que reprovam**

Anexe ao final de `SignupUseCaseImplTest.java`, antes do `}` final:

```java
    /// Banco novo nao tem admin, logo nao ha quem promova. A variavel concede --
    /// nao cria conta: a pessoa ainda se cadastra sozinha.
    @Test
    void oPrimeiroCadastroComOEmailDeBootstrapNasceAdmin() {
        SignupUseCaseImpl comBootstrap = new SignupUseCaseImpl(
                userRepository, passwordEncoder, "chefe@prefeitura.gov.br");
        when(userRepository.countAdmins()).thenReturn(0L);

        User criado = comBootstrap.signup(
                User.builder().email("chefe@prefeitura.gov.br").fullName("Chefe").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.ADMIN);
    }

    /// A janela fecha sozinha: existindo admin, a condicao nunca mais e
    /// verdadeira, mesmo com a variavel configurada pra sempre.
    @Test
    void comAdminExistenteOBootstrapNaoVale() {
        SignupUseCaseImpl comBootstrap = new SignupUseCaseImpl(
                userRepository, passwordEncoder, "chefe@prefeitura.gov.br");
        when(userRepository.countAdmins()).thenReturn(1L);

        User criado = comBootstrap.signup(
                User.builder().email("chefe@prefeitura.gov.br").fullName("Chefe").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
    }

    @Test
    void outroEmailNaoVirapAdminNemComZeroAdmins() {
        SignupUseCaseImpl comBootstrap = new SignupUseCaseImpl(
                userRepository, passwordEncoder, "chefe@prefeitura.gov.br");

        User criado = comBootstrap.signup(
                User.builder().email("outra@pessoa.com").fullName("Outra").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
    }

    /// Sem a variavel configurada -- o caso normal -- nada de especial acontece,
    /// e nem se consulta o banco por admin.
    @Test
    void semVariavelConfiguradaNinguemNasceAdmin() {
        SignupUseCaseImpl semBootstrap = new SignupUseCaseImpl(
                userRepository, passwordEncoder, "");

        User criado = semBootstrap.signup(
                User.builder().email("qualquer@pessoa.com").fullName("Qualquer").build(),
                "segredo123");

        assertThat(criado.getRole()).isEqualTo(Role.STUDENT);
        verify(userRepository, org.mockito.Mockito.never()).countAdmins();
    }
```

> Os testes que já existem no arquivo constroem `SignupUseCaseImpl` com dois argumentos. Atualize essas construções para passar `""` como terceiro.

- [ ] **Step 2: Rodar e ver falhar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=SignupUseCaseImplTest
```

Esperado: **erro de compilação** — o construtor ainda tem dois parâmetros.

- [ ] **Step 3: Implementar**

Em `SignupUseCaseImpl.java`, troque o campo/construtor e a atribuição de papel:

```java
    private final UserRepositoryPort userRepository;
    private final PasswordEncoder passwordEncoder;
    private final String bootstrapAdminEmail;

    public SignupUseCaseImpl(UserRepositoryPort userRepository,
                             PasswordEncoder passwordEncoder,
                             @Value("${app.bootstrap-admin-email:}") String bootstrapAdminEmail) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.bootstrapAdminEmail = bootstrapAdminEmail;
    }
```

Substitua a linha `user.setRole(Role.STUDENT);` por:

```java
        // O papel e cravado aqui, nao vem do request: aceitar o que o cliente
        // mandar deixaria qualquer um criar conta de admin por este endpoint,
        // que e publico.
        //
        // A unica excecao e o bootstrap, e ela se fecha sozinha: num banco novo
        // nao existe admin, logo nao ha quem promova. A variavel CONCEDE o papel
        // a uma conta que a propria pessoa criou -- nao cria conta nenhuma -- e
        // no instante em que existe um admin a condicao nunca mais e verdadeira.
        user.setRole(ehOBootstrap(user.getEmail()) ? Role.ADMIN : Role.STUDENT);
```

E adicione o método privado no fim da classe:

```java
    private boolean ehOBootstrap(String email) {
        return bootstrapAdminEmail != null
                && !bootstrapAdminEmail.isBlank()
                && bootstrapAdminEmail.equalsIgnoreCase(email)
                && userRepository.countAdmins() == 0;
    }
```

Import necessário:

```java
import org.springframework.beans.factory.annotation.Value;
```

- [ ] **Step 4: Rodar e ver passar**

```bash
cd smartboarding-api && ./mvnw -o test -Dtest=SignupUseCaseImplTest
```

Esperado: **todos passam**.

- [ ] **Step 5: Ligar a configuração**

Em `application.properties`, adicione:

```properties
app.bootstrap-admin-email=${BOOTSTRAP_ADMIN_EMAIL:}
```

Em `.env.example`, na seção de sessão (perto do `JWT_SECRET`):

```bash
# Primeiro admin de um ambiente novo. Quem se cadastrar com este e-mail nasce
# ADMIN, mas SÓ enquanto não existir nenhum admin no sistema — depois disso a
# variável não faz mais nada, mesmo configurada. Deixe vazio em dev: o seed já
# cria admins.
BOOTSTRAP_ADMIN_EMAIL=
```

- [ ] **Step 6: Commit**

```bash
git add smartboarding-api
git commit -m "feat(auth): primeiro admin de um ambiente novo por BOOTSTRAP_ADMIN_EMAIL"
```

---

### Task 5: Papel na ficha do usuário (app)

**Files:**
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user/dto/StudentProfileResponse.java`
- Modify: `smartboarding_app/lib/features/users/models/student_profile_model.dart`
- Modify: `smartboarding_app/lib/features/users/services/user_service.dart`
- Modify: `smartboarding_app/lib/features/users/widgets/student_profile_card.dart`
- Test: `smartboarding_app/test/widget/student_profile_card_test.dart`

**Interfaces:**
- Consumes: `PATCH /api/users/{id}/role` (Task 2).
- Produces: `UserService.setRole(String userId, String role) → StudentProfile`; `StudentProfile.role` (String, `"ADMIN"` ou `"STUDENT"`).

- [ ] **Step 1: Expor o papel na resposta da API**

Em `StudentProfileResponse.java`, adicione `String role` ao record logo depois de `boolean isActive`.

O `profileOf(...)` do `UserController` constrói o record **posicionalmente**, então ele quebra na compilação. A última linha da construção passa de:

```java
                user.isActive(), attendance, changes);
```

para:

```java
                user.isActive(), user.getRole().name(), attendance, changes);
```

- [ ] **Step 2: Escrever o teste de widget que reprova**

Anexe a `student_profile_card_test.dart`:

O arquivo já tem uma fixture `perfil` (um `StudentProfile` com `isActive: false`) e um helper `wrap(Widget)`. Reaproveite os dois — o widget sob teste é `StudentProfileBody`, cuja assinatura passa a ser `({profile, onToggle, onToggleRole, ehAPropriaConta, busy})`.

```dart
  StudentProfile comPapel(String role, {bool ativa = true}) => StudentProfile(
    id: perfil.id,
    fullName: perfil.fullName,
    email: perfil.email,
    phone: perfil.phone,
    address: perfil.address,
    birthDate: perfil.birthDate,
    course: perfil.course,
    institution: perfil.institution,
    isActive: ativa,
    role: role,
    recentAttendance: perfil.recentAttendance,
    statusHistory: perfil.statusHistory,
  );

  /// A trava aparece como ausencia de opcao, nao como erro depois do toque: o
  /// admin nao descobre que nao podia so quando a API recusa.
  testWidgets('a propria conta nao oferece troca de papel', (tester) async {
    await tester.pumpWidget(wrap(StudentProfileBody(
      profile: comPapel('ADMIN'),
      onToggle: (_) {},
      onToggleRole: () {},
      ehAPropriaConta: true,
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_role_action')), findsNothing);
  });

  testWidgets('conta de aluno oferece promover', (tester) async {
    await tester.pumpWidget(wrap(StudentProfileBody(
      profile: comPapel('STUDENT'),
      onToggle: (_) {},
      onToggleRole: () {},
      ehAPropriaConta: false,
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_role_action')), findsOneWidget);
    expect(find.text('Tornar administrador'), findsOneWidget);
  });

  /// Promover conta desativada produz um admin que nao consegue entrar.
  testWidgets('conta desativada nao oferece promover', (tester) async {
    await tester.pumpWidget(wrap(StudentProfileBody(
      profile: comPapel('STUDENT', ativa: false),
      onToggle: (_) {},
      onToggleRole: () {},
      ehAPropriaConta: false,
    )));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(find.byKey(const Key('profile_role_action')));
    expect(tile.enabled, isFalse);
  });
```

`StudentProfileBody` ganha dois campos obrigatórios — `final VoidCallback onToggleRole;` e `final bool ehAPropriaConta;` — declarados junto de `busy` e `onToggle`, e exigidos no construtor. Os pontos que já constroem o widget precisam passar os dois.

- [ ] **Step 3: Rodar e ver falhar**

```bash
cd smartboarding_app && flutter test test/widget/student_profile_card_test.dart
```

Esperado: **falha** — a chave `profile_role_action` não existe.

- [ ] **Step 4: Implementar**

No `student_profile_model.dart`, adicione `final String role;` ao modelo, ao construtor e ao `fromJson` (`role: json['role'] as String`).

No `user_service.dart`, adicione:

```dart
  /// Concede ou retira acesso administrativo. Não cria conta — a conta já é da
  /// pessoa.
  Future<StudentProfile> setRole(String userId, String role) async {
    final response = await _dio.patch(
      '/api/users/$userId/role',
      data: {'role': role},
    );
    return StudentProfile.fromJson(response.data['data'] as Map<String, dynamic>);
  }
```

No `student_profile_card.dart`, adicione a ação abaixo do `SwitchListTile`, com a mesma disciplina de `_busy` que o `_toggle` já usa:

```dart
        if (!ehAPropriaConta)
          ListTile(
            key: const Key('profile_role_action'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: Text(
              profile.role == 'ADMIN'
                  ? 'Remover acesso de administrador'
                  : 'Tornar administrador',
            ),
            subtitle: const Text('Fica registrado com seu nome e a hora.'),
            enabled: !busy && (profile.role == 'ADMIN' || profile.isActive),
            onTap: busy ? null : onToggleRole,
          ),
```

- [ ] **Step 5: Rodar e ver passar**

```bash
cd smartboarding_app && flutter analyze && flutter test
```

Esperado: analyze limpo, **todos os testes passam**.

- [ ] **Step 6: Commit**

```bash
git add smartboarding-api/src/main/java smartboarding_app/lib smartboarding_app/test
git commit -m "feat(app): conceder e retirar acesso admin pela ficha do usuario"
```

---

### Task 6: Documentação

**Files:**
- Modify: `smartboarding-api/docs/spec.md`
- Modify: `smartboarding_app/docs/PAGES.md`

- [ ] **Step 1: Atualizar as regras de negócio**

Em `smartboarding-api/docs/spec.md`, na seção 4.1, reescreva o trecho de `POST /api/auth/register` para:

```markdown
- **RN13** — Aluno se cadastra sozinho (`POST /api/auth/signup`, só nome, e-mail e senha) e já
  recebe a sessão. A conta nasce **sem rota** e com papel `STUDENT`.
  - **Ninguém cria conta de administrador.** Acesso administrativo é concedido sobre uma conta
    que a própria pessoa criou, por `PATCH /api/users/{id}/role` — ver RN27.
  - `POST /api/auth/google` entra pelo Google; quem entrou assim pode definir uma senha local
    depois (`POST /api/me/password`) e passa a ter os dois caminhos.
- **RN27** — Papel administrativo é **concessão**, não cadastro. Um `ADMIN` promove ou rebaixa
  uma conta existente. Quatro travas: não rebaixa a si mesmo, não rebaixa o último admin, não
  promove conta desativada, e declarar o papel que já vale é no-op (não é erro). Toda mudança
  entra no `user_status_log` com quem concedeu. Remover um admin são duas ações deliberadas:
  rebaixar e depois desativar.
- **RN28** — Primeiro admin de um ambiente novo: quem se cadastrar com o e-mail de
  `BOOTSTRAP_ADMIN_EMAIL` nasce `ADMIN`, **e só enquanto o sistema tiver zero admins**. A
  variável concede o papel a uma conta que a pessoa criou; não cria conta.
```

Na tabela de endpoints, remova a linha de `POST /api/auth/register` e adicione:

```markdown
| PATCH | `/api/users/{id}/role` | ADMIN | `{role: "ADMIN"\|"STUDENT"}` | `StudentProfileResponse` | `400 CANNOT_DEMOTE_SELF`, `400 LAST_ADMIN`, `400 INACTIVE_ACCOUNT`, `404` |
```

- [ ] **Step 2: Atualizar o índice de telas**

Em `smartboarding_app/docs/PAGES.md`, na linha da tela **Usuários**, acrescente a gestão de papel ao propósito e `PATCH /api/users/{id}/role` ao contrato de API.

- [ ] **Step 3: Conferir que nada ficou apontando pro endpoint morto**

```bash
cd .. && git grep -rn "auth/register" -- '*.md' '*.java' '*.dart'
```

Esperado: **nenhuma saída**.

- [ ] **Step 4: Commit**

```bash
git add smartboarding-api/docs/spec.md smartboarding_app/docs/PAGES.md
git commit -m "docs: acesso admin por concessao, nao por criacao de conta"
```

---

## Verificação final

- [ ] `cd smartboarding-api && ./mvnw verify` → BUILD SUCCESS, gates do JaCoCo verdes
- [ ] `cd smartboarding_app && flutter analyze && flutter test --coverage && ./scripts/coverage-gate.sh` → limpo e verde
- [ ] `git grep -rn "auth/register"` → nenhuma saída
- [ ] Manual, com o ambiente de pé: promover um aluno pela ficha, conferir que ele vê o painel do admin **no próximo login** (o token antigo ainda carrega o papel velho por até 1h), rebaixar, e confirmar que rebaixar o último admin é recusado
