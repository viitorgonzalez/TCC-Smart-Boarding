# Recuperação de senha (RN22) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Quem esqueceu a senha recupera o acesso sozinho, por código de 6 dígitos enviado por e-mail, sem que o endpoint público revele quais e-mails existem.

**Architecture:** Tabela própria e efêmera (`password_reset_requests`), use case na arquitetura hexagonal já usada em `registration`, e duas telas Flutter derivadas dos mockups existentes. O padrão de segurança é copiado de `RegistrationUseCaseImpl`, que já resolveu o mesmo problema neste repo — inclusive a armadilha transacional descrita na Task 4.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · Flyway · Postgres 16 · JUnit 5 + Mockito + AssertJ — Flutter/Dart 3.11 · Provider · Dio · mocktail.

**Spec:** `docs/superpowers/specs/2026-09-08-hardening-pre-producao-design.md` (§4.1 e §4.6)

**Escopo desta PR:** a 1ª das 5 da spec §6. Entrega a RN22 completa (API + app) e a correção do aviso de branch. As outras quatro frentes têm planos próprios.

## Global Constraints

- Branch de trabalho: `feature/hardening-pre-producao` (já criada a partir da `main`).
- Última migration aplicada é a **V18** — a nova é `V19`. Nunca editar migration já aplicada.
- Nenhum TTL, cooldown ou limite literal no código: tudo em `application.properties` sob `app.password-reset.*`.
- Nenhum arquivo tocado pode passar de **300 linhas** (gate do CI).
- Comentário explica o **porquê**, nunca o quê.
- Commit convencional. **Sem** `Co-Authored-By` de IA.
- **Não** commitar, pushar ou abrir PR sem aprovação explícita do autor. Os commits descritos nas tasks são preparados e apresentados; a autorização vem antes de executar.
- Senha nova respeita RN10: mínimo 6 caracteres.
- Rodar da pasta certa: `smartboarding-api/` para Maven, `smartboarding_app/` para Flutter.

## File Structure

**API** (`smartboarding-api/`)

| Arquivo | Responsabilidade |
|---|---|
| `src/main/resources/db/migration/V19__password_reset.sql` | tabela `password_reset_requests` |
| `domain/passwordreset/entity/PasswordResetRequest.java` | entidade + regras de expiração/tentativas |
| `domain/passwordreset/port/in/RequestPasswordResetUseCase.java` | porta: pedir código |
| `domain/passwordreset/port/in/ResetPasswordUseCase.java` | porta: trocar senha |
| `domain/passwordreset/port/out/PasswordResetRepositoryPort.java` | porta de persistência |
| `infrastructure/persistence/passwordreset/PasswordResetJpaRepository.java` | Spring Data |
| `infrastructure/persistence/passwordreset/PasswordResetRepositoryAdapter.java` | adapter da porta |
| `application/passwordreset/PasswordResetEmails.java` | corpos de e-mail (fora do use case) |
| `application/passwordreset/PasswordResetUseCaseImpl.java` | as duas operações |
| `infrastructure/web/user/dto/ForgotPasswordRequest.java` | DTO de entrada |
| `infrastructure/web/user/dto/ResetPasswordRequest.java` | DTO de entrada |
| `infrastructure/web/user/AuthController.java` *(modificar)* | dois endpoints novos |
| `infrastructure/config/SecurityConfig.java` *(modificar)* | libera as duas rotas |
| `src/main/resources/application.properties` *(modificar)* | `app.password-reset.*` |
| `src/test/.../application/passwordreset/PasswordResetUseCaseImplTest.java` | testes |

**App** (`smartboarding_app/`)

| Arquivo | Responsabilidade |
|---|---|
| `lib/features/auth/services/auth_service.dart` *(modificar)* | duas chamadas novas |
| `lib/features/auth/screens/forgot_password_screen.dart` | pedir o código |
| `lib/features/auth/screens/reset_password_screen.dart` | código + nova senha |
| `lib/features/auth/screens/login_screen.dart` *(modificar)* | link de entrada |
| `test/widget/password_reset_test.dart` | validação das duas telas |

**Docs** — `CLAUDE.md`, `smartboarding-api/CLAUDE.md`, `../personal-harness/docs/repos.md`, `smartboarding-api/docs/spec.md`, `smartboarding_app/docs/specs/autenticacao/password-reset.md`.

---

### Task 1: Verdade sobre a branch

Mecânico e independente do resto — vai primeiro porque é o item de maior risco parado (faz alguém trabalhar na branch errada) e o de menor custo.

**Files:**
- Modify: `CLAUDE.md:5`
- Modify: `smartboarding-api/CLAUDE.md` (mesmo aviso, se presente)
- Modify: `../personal-harness/docs/repos.md`

**Interfaces:** nenhuma — só documentação.

- [ ] **Step 1: Confirmar que o aviso é mesmo falso**

```bash
cd /home/viitorgonzalez/Documentos/personal-harness/TCC-Smart-Boarding
git fetch -q origin && git rev-list --left-right --count origin/main...origin/fix/project-setup
```

Esperado: `1	0` — a `main` está à frente, e nada exclusivo sobrou na outra branch. Se vier diferente, **pare**: a premissa mudou e o texto precisa ser outro.

- [ ] **Step 2: Localizar todas as ocorrências**

```bash
grep -rn "fix/project-setup" CLAUDE.md smartboarding-api/CLAUDE.md smartboarding_app/docs/ ../personal-harness/docs/repos.md 2>/dev/null
```

- [ ] **Step 3: Substituir o aviso nos dois `CLAUDE.md`**

Remover o bloco de citação da linha 5 e, no lugar, deixar registrado o que o leitor precisa saber hoje:

```markdown
> ℹ️ **A `main` é a fonte da verdade.** Alinhada em 08/09/2026 (PR #9) — o app Flutter e a API
> completa estão nela. Branches de feature saem da `main` e voltam pra ela.
```

- [ ] **Step 4: Corrigir o ponteiro no harness**

Em `../personal-harness/docs/repos.md`, trocar `main (⚠️ estado real em fix/project-setup)` por `main`.

- [ ] **Step 5: Verificar que não sobrou referência**

```bash
grep -rn "está desatualizada\|estado real em fix/project-setup" CLAUDE.md smartboarding-api/CLAUDE.md ../personal-harness/docs/repos.md
```

Esperado: nenhuma saída.

- [ ] **Step 6: Commit (após aprovação do autor)**

```bash
git add CLAUDE.md smartboarding-api/CLAUDE.md
git commit -m "docs: main passa a ser a fonte da verdade

O aviso de que a main estava desatrás da fix/project-setup virou falso quando a
PR #9 alinhou as duas. Aviso errado sobre branch faz trabalho nascer no lugar
errado."
```

O `repos.md` vive no repo do harness e é commitado lá, separadamente.

---

### Task 2: Schema, entidade e persistência do reset

**Files:**
- Create: `smartboarding-api/src/main/resources/db/migration/V19__password_reset.sql`
- Create: `.../domain/passwordreset/entity/PasswordResetRequest.java`
- Create: `.../domain/passwordreset/port/out/PasswordResetRepositoryPort.java`
- Create: `.../infrastructure/persistence/passwordreset/PasswordResetJpaRepository.java`
- Create: `.../infrastructure/persistence/passwordreset/PasswordResetRepositoryAdapter.java`

**Interfaces:**
- Consumes: nada de tasks anteriores.
- Produces: `PasswordResetRequest` (com `isExpired(LocalDateTime)`, `getAttempts()`, `getCodeHash()`, `getUsedAt()`); `PasswordResetRepositoryPort.save(PasswordResetRequest)`, `.findLatestOpenByUserId(UUID)`, `.invalidateAllForUser(UUID, LocalDateTime)` — o nome longo `findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc` é derivação do Spring Data e fica **só** dentro do repositório JPA.

- [ ] **Step 1: Escrever a migration**

Arquivo `V19__password_reset.sql`:

```sql
-- Recuperacao de senha (RN22). Tabela propria em vez de colunas em users: o dado
-- e efemero e nao pertence ao perfil. Codigo fica hasheado -- 6 digitos tem pouca
-- entropia, entao a defesa e validade curta + limite de tentativas + uso unico.
CREATE TABLE password_reset_requests (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash   VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP    NOT NULL,
    attempts    INT          NOT NULL DEFAULT 0,
    used_at     TIMESTAMP,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_reset_user ON password_reset_requests(user_id);
```

- [ ] **Step 2: Escrever a entidade**

```java
package com.smartboarding.smartboarding_api.domain.passwordreset.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/// Pedido de redefinicao de senha. So o hash do codigo e guardado -- o valor puro
/// existe apenas no e-mail enviado.
@Entity
@Table(name = "password_reset_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PasswordResetRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "code_hash", nullable = false)
    private String codeHash;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Builder.Default
    @Column(nullable = false)
    private int attempts = 0;

    @Column(name = "used_at")
    private LocalDateTime usedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    public boolean isExpired(LocalDateTime now) {
        return now.isAfter(expiresAt);
    }

    public boolean isUsed() {
        return usedAt != null;
    }
}
```

- [ ] **Step 3: Escrever a porta de saída**

```java
package com.smartboarding.smartboarding_api.domain.passwordreset.port.out;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetRepositoryPort {

    PasswordResetRequest save(PasswordResetRequest request);

    /// Pedido em aberto mais recente do usuario -- e o unico que pode ser usado.
    Optional<PasswordResetRequest> findLatestOpenByUserId(UUID userId);

    /// Marca todos os pedidos em aberto como usados. Emitir codigo novo invalida os
    /// anteriores, senao um codigo antigo vazado continuaria valendo.
    void invalidateAllForUser(UUID userId, LocalDateTime at);
}
```

- [ ] **Step 4: Escrever o repositório Spring Data**

```java
package com.smartboarding.smartboarding_api.infrastructure.persistence.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetJpaRepository extends JpaRepository<PasswordResetRequest, UUID> {

    Optional<PasswordResetRequest> findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId);

    @Modifying
    @Query("UPDATE PasswordResetRequest r SET r.usedAt = :at WHERE r.userId = :userId AND r.usedAt IS NULL")
    void invalidateAllForUser(@Param("userId") UUID userId, @Param("at") LocalDateTime at);
}
```

- [ ] **Step 5: Escrever o adapter**

```java
package com.smartboarding.smartboarding_api.infrastructure.persistence.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
public class PasswordResetRepositoryAdapter implements PasswordResetRepositoryPort {

    private final PasswordResetJpaRepository jpaRepository;

    public PasswordResetRepositoryAdapter(PasswordResetJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public PasswordResetRequest save(PasswordResetRequest request) {
        return jpaRepository.save(request);
    }

    @Override
    public Optional<PasswordResetRequest> findLatestOpenByUserId(UUID userId) {
        return jpaRepository.findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(userId);
    }

    @Override
    public void invalidateAllForUser(UUID userId, LocalDateTime at) {
        jpaRepository.invalidateAllForUser(userId, at);
    }
}
```

- [ ] **Step 6: Verificar que o schema sobe**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress verify
```

Esperado: `BUILD SUCCESS`. O teste de integração (`SmartboardingApiApplicationIT`) sobe Postgres via Testcontainers e aplica todas as migrations — é ele que prova que a V19 é válida.

- [ ] **Step 7: Commit (após aprovação do autor)**

```bash
git add smartboarding-api/src/main/resources/db/migration/V19__password_reset.sql \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/passwordreset \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/passwordreset
git commit -m "feat(api): schema e persistencia do pedido de redefinicao de senha"
```

---

### Task 3: Solicitar o código (`forgot-password`)

**Files:**
- Create: `.../domain/passwordreset/port/in/RequestPasswordResetUseCase.java`
- Create: `.../application/passwordreset/PasswordResetEmails.java`
- Create: `.../application/passwordreset/PasswordResetUseCaseImpl.java`
- Modify: `src/main/resources/application.properties`
- Test: `src/test/.../application/passwordreset/PasswordResetUseCaseImplTest.java`

**Interfaces:**
- Consumes: `PasswordResetRepositoryPort` (Task 2), `PasswordResetRequest` (Task 2), `UserRepositoryPort.findByEmail(String)`, `EmailPort.send(String,String,String)`.
- Produces: `RequestPasswordResetUseCase.request(String email)` — `void`, nunca lança por e-mail inexistente.

- [ ] **Step 1: Adicionar a configuração**

Em `application.properties`, abaixo de `app.timezone`:

```properties
# Recuperacao de senha (RN22). Validade curta e limite de tentativas sao a defesa
# do codigo de 6 digitos, que tem pouca entropia por natureza.
app.password-reset.code-ttl-minutes=${PASSWORD_RESET_TTL_MINUTES:15}
app.password-reset.max-attempts=${PASSWORD_RESET_MAX_ATTEMPTS:5}
app.password-reset.resend-cooldown-seconds=${PASSWORD_RESET_COOLDOWN_SECONDS:60}
```

- [ ] **Step 2: Escrever a porta de entrada**

```java
package com.smartboarding.smartboarding_api.domain.passwordreset.port.in;

public interface RequestPasswordResetUseCase {

    /// Nunca sinaliza se a conta existe: o endpoint e publico e uma resposta
    /// diferente por e-mail inexistente viraria detector de cadastro (RN22).
    void request(String email);
}
```

- [ ] **Step 3: Escrever os corpos de e-mail**

```java
package com.smartboarding.smartboarding_api.application.passwordreset;

/// Texto do e-mail fora do use case: muda por motivo diferente do que muda a regra.
final class PasswordResetEmails {

    static final String SUBJECT = "Redefinicao de senha Smart Boarding";

    private PasswordResetEmails() {}

    static String code(String code, long ttlMinutes) {
        return "<p>Seu codigo para redefinir a senha: <strong>" + code + "</strong></p>"
                + "<p>Valido por " + ttlMinutes + " minutos.</p>"
                + "<p>Se nao foi voce que pediu, ignore este e-mail: a senha atual continua valendo.</p>";
    }
}
```

- [ ] **Step 4: Escrever o teste que falha**

```java
package com.smartboarding.smartboarding_api.application.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PasswordResetUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 8, 10, 0);
    private static final UUID USER_ID = UUID.randomUUID();
    private static final String EMAIL = "aluno@edu.unifor.br";

    @Mock PasswordResetRepositoryPort resetRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock EmailPort emailPort;
    @Mock PasswordEncoder passwordEncoder;

    private PasswordResetUseCaseImpl useCase;

    private Clock clockAt(LocalDateTime moment) {
        return Clock.fixed(moment.atZone(ZONE).toInstant(), ZONE);
    }

    private PasswordResetUseCaseImpl useCaseAt(LocalDateTime moment) {
        return new PasswordResetUseCaseImpl(resetRepository, userRepository, emailPort,
                passwordEncoder, clockAt(moment), 15, 5, 60);
    }

    @BeforeEach
    void setUp() {
        User user = User.builder().id(USER_ID).email(EMAIL).build();
        when(userRepository.findByEmail(EMAIL)).thenReturn(Optional.of(user));
        when(userRepository.findByEmail("naoexiste@edu.unifor.br")).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("hash-fake");
        when(resetRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.empty());
        useCase = useCaseAt(NOW);
    }

    @Test
    void emailInexistenteNaoGeraPedidoNemEmail() {
        useCase.request("naoexiste@edu.unifor.br");

        verify(resetRepository, never()).save(any());
        verify(emailPort, never()).send(any(), any(), any());
    }

    @Test
    void pedidoGravaSoOHashComValidadeCurta() {
        useCase.request(EMAIL);

        ArgumentCaptor<PasswordResetRequest> captor = ArgumentCaptor.forClass(PasswordResetRequest.class);
        verify(resetRepository).save(captor.capture());
        PasswordResetRequest saved = captor.getValue();

        assertThat(saved.getUserId()).isEqualTo(USER_ID);
        assertThat(saved.getCodeHash()).isEqualTo("hash-fake");
        assertThat(saved.getExpiresAt()).isEqualTo(NOW.plusMinutes(15));
        assertThat(saved.getAttempts()).isZero();
        assertThat(saved.getUsedAt()).isNull();
    }

    @Test
    void emailLevaCodigoDeSeisDigitos() {
        useCase.request(EMAIL);

        ArgumentCaptor<String> body = ArgumentCaptor.forClass(String.class);
        verify(emailPort).send(eq(EMAIL), anyString(), body.capture());
        assertThat(body.getValue()).containsPattern("\\d{6}");
    }

    @Test
    void emitirCodigoNovoInvalidaOsAnteriores() {
        useCase.request(EMAIL);

        verify(resetRepository).invalidateAllForUser(USER_ID, NOW);
    }

    @Test
    void pedidoDentroDoCooldownNaoEnviaDeNovo() {
        PasswordResetRequest recente = PasswordResetRequest.builder()
                .userId(USER_ID).codeHash("hash").expiresAt(NOW.plusMinutes(15))
                .createdAt(NOW.minusSeconds(30)).build();
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(recente));

        useCase.request(EMAIL);

        verify(resetRepository, never()).save(any());
        verify(emailPort, never()).send(any(), any(), any());
    }

    @Test
    void falhaDeEmailNaoDesfazOPedido() {
        doThrow(new RuntimeException("Resend fora")).when(emailPort).send(any(), any(), any());

        useCase.request(EMAIL);

        verify(resetRepository).save(any());
    }
}
```

- [ ] **Step 5: Rodar e confirmar que falha**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress test -Dtest=PasswordResetUseCaseImplTest
```

Esperado: falha de compilação — `PasswordResetUseCaseImpl` não existe.

- [ ] **Step 6: Escrever a implementação**

```java
package com.smartboarding.smartboarding_api.application.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.in.RequestPasswordResetUseCase;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Service
public class PasswordResetUseCaseImpl implements RequestPasswordResetUseCase {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final PasswordResetRepositoryPort resetRepository;
    private final UserRepositoryPort userRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;
    private final Clock clock;
    private final long codeTtlMinutes;
    private final int maxAttempts;
    private final long resendCooldownSeconds;

    public PasswordResetUseCaseImpl(PasswordResetRepositoryPort resetRepository,
                                    UserRepositoryPort userRepository,
                                    EmailPort emailPort,
                                    PasswordEncoder passwordEncoder,
                                    Clock clock,
                                    @Value("${app.password-reset.code-ttl-minutes}") long codeTtlMinutes,
                                    @Value("${app.password-reset.max-attempts}") int maxAttempts,
                                    @Value("${app.password-reset.resend-cooldown-seconds}") long resendCooldownSeconds) {
        this.resetRepository = resetRepository;
        this.userRepository = userRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
        this.clock = clock;
        this.codeTtlMinutes = codeTtlMinutes;
        this.maxAttempts = maxAttempts;
        this.resendCooldownSeconds = resendCooldownSeconds;
    }

    @Override
    @Transactional
    public void request(String email) {
        Optional<User> found = userRepository.findByEmail(email);
        if (found.isEmpty()) {
            return;
        }
        User user = found.get();
        LocalDateTime now = LocalDateTime.now(clock);

        if (isWithinCooldown(user, now)) {
            return;
        }

        resetRepository.invalidateAllForUser(user.getId(), now);

        String code = generateCode();
        resetRepository.save(PasswordResetRequest.builder()
                .userId(user.getId())
                .codeHash(passwordEncoder.encode(code))
                .expiresAt(now.plusMinutes(codeTtlMinutes))
                .createdAt(now)
                .build());

        sendEmailBestEffort(email, PasswordResetEmails.SUBJECT,
                PasswordResetEmails.code(code, codeTtlMinutes));
    }

    // Silencioso: recusar em voz alta so quando existe pedido aberto entregaria
    // ao chamador a informacao de que aquele e-mail tem conta.
    private boolean isWithinCooldown(User user, LocalDateTime now) {
        return resetRepository.findLatestOpenByUserId(user.getId())
                .map(PasswordResetRequest::getCreatedAt)
                .filter(created -> created.plusSeconds(resendCooldownSeconds).isAfter(now))
                .isPresent();
    }

    // O envio roda dentro da transacao: deixar a excecao subir desfaria o pedido
    // inteiro e viraria 500. Quem nao recebeu pede outro codigo.
    private void sendEmailBestEffort(String to, String subject, String htmlBody) {
        try {
            emailPort.send(to, subject, htmlBody);
        } catch (Exception e) {
            log.error("Pedido gravado, mas o e-mail de redefinicao falhou: {}", e.getMessage());
        }
    }

    private String generateCode() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }
}
```

- [ ] **Step 7: Rodar e confirmar que passa**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress test -Dtest=PasswordResetUseCaseImplTest
```

Esperado: `Tests run: 6, Failures: 0, Errors: 0`.

- [ ] **Step 8: Commit (após aprovação do autor)**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/passwordreset/port/in \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/passwordreset \
        smartboarding-api/src/main/resources/application.properties \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/passwordreset
git commit -m "feat(api): solicitacao de codigo para redefinir senha

Responde igual com e sem conta cadastrada -- o endpoint e publico e nao pode
virar detector de e-mail. Emitir codigo novo invalida os anteriores."
```

---

### Task 4: Redefinir a senha (`reset-password`)

⚠️ **A armadilha desta task.** O método que troca a senha **não pode** ser `@Transactional`. Ele incrementa o contador de tentativas e lança exceção em seguida; numa transação única o rollback descarta o incremento, o limite nunca é atingido e a força bruta fica livre. Isso já aconteceu de verdade no fluxo de convite deste repo — o teste `limiteDeTentativasEhAtingido` abaixo existe para não deixar acontecer de novo.

**Files:**
- Create: `.../domain/passwordreset/port/in/ResetPasswordUseCase.java`
- Modify: `.../application/passwordreset/PasswordResetUseCaseImpl.java`
- Modify: `src/test/.../application/passwordreset/PasswordResetUseCaseImplTest.java`

**Interfaces:**
- Consumes: tudo da Task 3, mais `UserRepositoryPort.save(User)`.
- Produces: `ResetPasswordUseCase.reset(String email, String code, String newPassword)` — `void`; lança `BadRequestException` com código `INVALID_CODE`, `CODE_EXPIRED` ou `TOO_MANY_ATTEMPTS`.

- [ ] **Step 1: Escrever a porta de entrada**

```java
package com.smartboarding.smartboarding_api.domain.passwordreset.port.in;

public interface ResetPasswordUseCase {

    /// Troca a senha e queima o codigo. E-mail desconhecido devolve o mesmo erro de
    /// codigo invalido -- distinguir os dois casos revelaria quais contas existem.
    void reset(String email, String code, String newPassword);
}
```

- [ ] **Step 2: Escrever os testes que falham**

Acrescentar ao `PasswordResetUseCaseImplTest` (os campos e helpers do `setUp` já existem da Task 3):

```java
    private PasswordResetRequest pedidoAberto(String hash, int tentativas, LocalDateTime expiraEm) {
        return PasswordResetRequest.builder()
                .id(UUID.randomUUID())
                .userId(USER_ID)
                .codeHash(hash)
                .expiresAt(expiraEm)
                .attempts(tentativas)
                .createdAt(NOW.minusMinutes(1))
                .build();
    }

    @Test
    void codigoCorretoTrocaASenhaEQueimaOPedido() {
        PasswordResetRequest pedido = pedidoAberto("hash-do-codigo", 0, NOW.plusMinutes(10));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("123456", "hash-do-codigo")).thenReturn(true);
        when(passwordEncoder.encode("senhaNova1")).thenReturn("hash-da-senha-nova");
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        useCase.reset(EMAIL, "123456", "senhaNova1");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(userCaptor.getValue().getPassword()).isEqualTo("hash-da-senha-nova");
        assertThat(pedido.getUsedAt()).isEqualTo(NOW);
    }

    @Test
    void codigoErradoIncrementaTentativasELanca() {
        PasswordResetRequest pedido = pedidoAberto("hash-do-codigo", 2, NOW.plusMinutes(10));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));
        when(passwordEncoder.matches("000000", "hash-do-codigo")).thenReturn(false);

        assertThatThrownBy(() -> useCase.reset(EMAIL, "000000", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");

        assertThat(pedido.getAttempts()).isEqualTo(3);
        verify(resetRepository).save(pedido);
        verify(userRepository, never()).save(any());
    }

    @Test
    void limiteDeTentativasEhAtingido() {
        // O contador so chega aqui porque o incremento nao vive numa transacao que
        // sofre rollback na excecao. Se alguem marcar reset() como @Transactional,
        // este teste continua passando com mock -- mas o comportamento real quebra.
        PasswordResetRequest pedido = pedidoAberto("hash-do-codigo", 5, NOW.plusMinutes(10));
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.of(pedido));

        assertThatThrownBy(() -> useCase.reset(EMAIL, "000000", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Muitas tentativas");

        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    void codigoExpiradoEhRecusado() {
        when(resetRepository.findLatestOpenByUserId(USER_ID))
                .thenReturn(Optional.of(pedidoAberto("hash-do-codigo", 0, NOW.minusMinutes(1))));

        assertThatThrownBy(() -> useCase.reset(EMAIL, "123456", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("expirado");
    }

    @Test
    void emailDesconhecidoDevolveOMesmoErroDeCodigoInvalido() {
        assertThatThrownBy(() -> useCase.reset("naoexiste@edu.unifor.br", "123456", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");
    }

    @Test
    void semPedidoAbertoDevolveCodigoInvalido() {
        when(resetRepository.findLatestOpenByUserId(USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.reset(EMAIL, "123456", "senhaNova1"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");
    }
```

Imports a acrescentar no topo do arquivo de teste:

```java
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
```

- [ ] **Step 3: Rodar e confirmar que falha**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress test -Dtest=PasswordResetUseCaseImplTest
```

Esperado: falha de compilação — `reset` não existe em `PasswordResetUseCaseImpl`.

- [ ] **Step 4: Implementar**

Na declaração da classe, acrescentar a interface:

```java
public class PasswordResetUseCaseImpl implements RequestPasswordResetUseCase, ResetPasswordUseCase {
```

E o método, **sem `@Transactional`**:

```java
    // Sem @Transactional de proposito: o contador de tentativas e gravado e a
    // excecao lancada em seguida. Numa transacao unica o rollback descartaria o
    // incremento, MAX_ATTEMPTS nunca seria atingido e a forca bruta ficaria livre
    // -- foi exatamente o bug do fluxo de convite deste repo.
    @Override
    public void reset(String email, String code, String newPassword) {
        User user = userRepository.findByEmail(email).orElseThrow(this::invalidCode);
        PasswordResetRequest request = resetRepository.findLatestOpenByUserId(user.getId())
                .orElseThrow(this::invalidCode);

        LocalDateTime now = LocalDateTime.now(clock);
        if (request.isExpired(now)) {
            throw new BadRequestException("CODE_EXPIRED", "Código expirado, peça um novo.");
        }
        if (request.getAttempts() >= maxAttempts) {
            throw new BadRequestException("TOO_MANY_ATTEMPTS", "Muitas tentativas, peça um novo código.");
        }
        if (!passwordEncoder.matches(code, request.getCodeHash())) {
            request.setAttempts(request.getAttempts() + 1);
            resetRepository.save(request);
            throw invalidCode();
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Uso unico: codigo que segue valendo e replayavel se vazar.
        request.setUsedAt(now);
        resetRepository.save(request);
        resetRepository.invalidateAllForUser(user.getId(), now);
    }

    private BadRequestException invalidCode() {
        return new BadRequestException("INVALID_CODE", "Código inválido ou expirado.");
    }
```

Imports novos: `com.smartboarding.smartboarding_api.domain.passwordreset.port.in.ResetPasswordUseCase` e `com.smartboarding.smartboarding_api.shared.exception.BadRequestException`.

- [ ] **Step 5: Rodar e confirmar que passa**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress test -Dtest=PasswordResetUseCaseImplTest
```

Esperado: `Tests run: 12, Failures: 0, Errors: 0`.

- [ ] **Step 6: Conferir o tamanho do arquivo (gate do CI)**

```bash
wc -l smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/passwordreset/PasswordResetUseCaseImpl.java
```

Esperado: abaixo de 300. Se passar, extrair a validação para um método privado coeso — não espalhar em arquivo novo só para contar linha.

- [ ] **Step 7: Commit (após aprovação do autor)**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/passwordreset/port/in/ResetPasswordUseCase.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/passwordreset/PasswordResetUseCaseImpl.java \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/passwordreset/PasswordResetUseCaseImplTest.java
git commit -m "feat(api): redefinicao de senha por codigo de uso unico

O incremento de tentativas fica fora de transacao de proposito: com rollback na
excecao o limite nunca seria atingido, que foi o bug de forca bruta do fluxo de
convite. E-mail desconhecido devolve o mesmo erro de codigo invalido."
```

---

### Task 5: Endpoints públicos

**Files:**
- Create: `.../infrastructure/web/user/dto/ForgotPasswordRequest.java`
- Create: `.../infrastructure/web/user/dto/ResetPasswordRequest.java`
- Modify: `.../infrastructure/web/user/AuthController.java`
- Modify: `.../infrastructure/config/SecurityConfig.java`

**Interfaces:**
- Consumes: `RequestPasswordResetUseCase.request(String)` e `ResetPasswordUseCase.reset(String,String,String)`.
- Produces: `POST /api/auth/forgot-password` e `POST /api/auth/reset-password`, ambos devolvendo `ApiResponse.success()`.

- [ ] **Step 1: Escrever os DTOs**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ForgotPasswordRequest(
        @NotBlank @Email @Size(max = 100) String email
) {}
```

```java
package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank @Email @Size(max = 100) String email,
        @NotBlank @Pattern(regexp = "\\d{6}", message = "O código tem 6 dígitos") String code,
        /// RN10: senha minima de 6 caracteres.
        @NotBlank @Size(min = 6, max = 100) String newPassword
) {}
```

- [ ] **Step 2: Acrescentar os endpoints ao `AuthController`**

No construtor, receber os dois use cases novos e guardá-los em campos `final`. Depois:

```java
    /// Responde igual havendo conta ou nao (RN22) -- por isso nao devolve dado nenhum.
    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<?>> forgotPassword(@RequestBody @Valid ForgotPasswordRequest request) {
        requestPasswordResetUseCase.request(request.email());
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<?>> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
        resetPasswordUseCase.reset(request.email(), request.code(), request.newPassword());
        return ResponseEntity.ok(ApiResponse.success());
    }
```

- [ ] **Step 3: Liberar as rotas no `SecurityConfig`**

Junto das outras rotas públicas de `/api/auth/**`:

```java
                        .requestMatchers(HttpMethod.POST, "/api/auth/forgot-password").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/reset-password").permitAll()
```

- [ ] **Step 4: Subir e exercitar de verdade**

```bash
cd smartboarding-api && docker compose up -d && ./run-local.sh
```

Em outro terminal:

```bash
curl -s -X POST localhost:8080/api/auth/forgot-password -H 'Content-Type: application/json' \
  -d '{"email":"naoexiste@edu.unifor.br"}' -w " | HTTP %{http_code}\n"
curl -s -X POST localhost:8080/api/auth/forgot-password -H 'Content-Type: application/json' \
  -d '{"email":"ana@student.com"}' -w " | HTTP %{http_code}\n"
```

Esperado: as **duas** respostas idênticas — `{"data":{"success":true}} | HTTP 200`. Resposta diferente entre elas é falha da RN22.

Pegar o código gravado (o e-mail não sai em dev) e fechar o ciclo:

```bash
docker exec postgres_smartboarding psql -U admin -d smartboarding_db -tAc \
  "select count(*) from password_reset_requests where used_at is null;"
```

Esperado: `1`.

- [ ] **Step 5: Rodar a suíte completa**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress clean verify
```

Esperado: `BUILD SUCCESS`, com os 12 testes novos somados aos 96 existentes.

- [ ] **Step 6: Commit (após aprovação do autor)**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/user \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java
git commit -m "feat(api): endpoints publicos de recuperacao de senha"
```

---

### Task 6: Telas do app

**Files:**
- Modify: `smartboarding_app/lib/features/auth/services/auth_service.dart`
- Create: `smartboarding_app/lib/features/auth/screens/forgot_password_screen.dart`
- Create: `smartboarding_app/lib/features/auth/screens/reset_password_screen.dart`
- Modify: `smartboarding_app/lib/features/auth/screens/login_screen.dart`
- Test: `smartboarding_app/test/widget/password_reset_test.dart`

**Interfaces:**
- Consumes: os dois endpoints da Task 5.
- Produces: `AuthService.forgotPassword(String email)` e `AuthService.resetPassword({required String email, required String code, required String newPassword})`, ambos `Future<void>`.

Base visual: `docs/design/figma-screens/recuperar-senha.png` e `redefinir-senha.png`. **Duas adaptações conscientes** ao mockup, porque o fluxo é por código e não por link: o botão diz **"Enviar código"** (não "Enviar link"), e a tela de redefinir ganha um campo de código acima dos dois de senha.

- [ ] **Step 1: Acrescentar as chamadas ao `AuthService`**

Dentro da classe `AuthService`, antes de `logout()`:

```dart
  /// Responde igual havendo conta ou não — a tela nunca deve afirmar que o
  /// e-mail existe (RN22).
  Future<void> forgotPassword(String email) async {
    await _dio.post('/api/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }
```

- [ ] **Step 2: Escrever a tela de pedir o código**

```dart
import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';

/// Pede o código de redefinição. Fundo Ash Grey como as outras telas de
/// autenticação (ver design-system.md).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _service = AuthService();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.forgotPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ashGrey,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Esqueci minha senha',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Insira seu e-mail cadastrado para enviarmos um código de '
                  'redefinição.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  key: const Key('forgot_email_field'),
                  label: 'Email',
                  controller: _emailCtrl,
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 24),
                LoadingFilledButton(
                  key: const Key('forgot_submit_button'),
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Enviar código',
                ),
                if (_sent) ...[
                  const SizedBox(height: 20),
                  _SentNotice(email: _emailCtrl.text.trim()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nunca afirma que a conta existe — o texto é o mesmo nos dois casos (RN22).
class _SentNotice extends StatelessWidget {
  final String email;
  const _SentNotice({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.positiveFg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.positiveFg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Se o e-mail existir, você vai receber o código em instantes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('forgot_go_to_reset'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(email: email),
              ),
            ),
            child: const Text('Já tenho o código'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Escrever a tela de redefinir**

```dart
import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../../../core/widgets/snackbar_utils.dart';
import '../services/auth_service.dart';

/// Código e nova senha na mesma tela: o backend valida os dois juntos, então não
/// há estado intermediário pra guardar.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = AuthService();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.resetPassword(
        email: widget.email,
        code: _codeCtrl.text.trim(),
        newPassword: _passCtrl.text,
      );
      if (!mounted) return;
      showSuccessSnackBar(context, 'Senha redefinida. Faça login.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, AppException.fromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ashGrey,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Redefinir senha',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha uma senha forte que você não tenha utilizado antes.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  key: const Key('reset_code_field'),
                  label: 'Código recebido por e-mail',
                  controller: _codeCtrl,
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().length != 6)
                      ? 'O código tem 6 dígitos'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  key: const Key('reset_password_field'),
                  label: 'Nova senha',
                  controller: _passCtrl,
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  key: const Key('reset_confirm_field'),
                  label: 'Confirmar nova senha',
                  controller: _confirmCtrl,
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: (v) =>
                      (v != _passCtrl.text) ? 'As senhas não conferem' : null,
                ),
                const SizedBox(height: 28),
                LoadingFilledButton(
                  key: const Key('reset_submit_button'),
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Redefinir senha',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Ligar no login**

Em `login_screen.dart`, logo abaixo do `TextButton` de "Tenho um convite":

```dart
                TextButton(
                  key: const Key('login_forgot_password'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
```

Import novo: `import 'forgot_password_screen.dart';`

- [ ] **Step 5: Escrever o teste de widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/auth/screens/reset_password_screen.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('código com menos de 6 dígitos é recusado', (tester) async {
    await tester.pumpWidget(
      wrap(const ResetPasswordScreen(email: 'aluno@edu.unifor.br')),
    );

    await tester.enterText(find.byKey(const Key('reset_code_field')), '123');
    await tester.enterText(
      find.byKey(const Key('reset_password_field')),
      'senhaNova1',
    );
    await tester.enterText(
      find.byKey(const Key('reset_confirm_field')),
      'senhaNova1',
    );
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('O código tem 6 dígitos'), findsOneWidget);
  });

  testWidgets('senha e confirmação diferentes são recusadas', (tester) async {
    await tester.pumpWidget(
      wrap(const ResetPasswordScreen(email: 'aluno@edu.unifor.br')),
    );

    await tester.enterText(find.byKey(const Key('reset_code_field')), '123456');
    await tester.enterText(
      find.byKey(const Key('reset_password_field')),
      'senhaNova1',
    );
    await tester.enterText(
      find.byKey(const Key('reset_confirm_field')),
      'outraSenha',
    );
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não conferem'), findsOneWidget);
  });

  testWidgets('senha curta é recusada (RN10)', (tester) async {
    await tester.pumpWidget(
      wrap(const ResetPasswordScreen(email: 'aluno@edu.unifor.br')),
    );

    await tester.enterText(find.byKey(const Key('reset_code_field')), '123456');
    await tester.enterText(find.byKey(const Key('reset_password_field')), 'abc');
    await tester.enterText(find.byKey(const Key('reset_confirm_field')), 'abc');
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Rodar o gate do app**

```bash
cd smartboarding_app && dart format . && flutter analyze && flutter test
```

Esperado: `No issues found!` e todos os testes passando (19 existentes + 3 novos).

- [ ] **Step 7: Conferir na tela**

```bash
cd smartboarding_app && flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Percorrer: login → "Esqueci minha senha" → enviar → "Já tenho o código" → código do banco + senha nova → login com a senha nova.

- [ ] **Step 8: Commit (após aprovação do autor)**

```bash
git add smartboarding_app/lib/features/auth smartboarding_app/test/widget/password_reset_test.dart
git commit -m "feat(app): telas de recuperacao e redefinicao de senha

Mockup pedia link; o fluxo e por codigo de 6 digitos pelo mesmo motivo do
convite (App Link exige dominio verificado). O aviso de envio nao afirma que a
conta existe."
```

---

### Task 7: Alinhar as specs ao que foi construído

A spec de tela e a RN22 descrevem link com token na URL. Deixar assim faria a próxima pessoa implementar de novo o que foi descartado.

**Files:**
- Modify: `smartboarding-api/docs/spec.md` (RN22)
- Modify: `smartboarding_app/docs/specs/autenticacao/password-reset.md`

**Interfaces:** nenhuma.

- [ ] **Step 1: Atualizar a RN22**

Trocar o texto atual por:

```markdown
- **RN22** — Recuperação de senha por **código de 6 dígitos** enviado por e-mail (não link: App
  Link exige domínio publicado e verificado, pendência de deploy — mesmo motivo do convite).
  `POST /api/auth/forgot-password` sempre responde `{success:true}`, mesmo se o e-mail não existir
  (não revela quais e-mails são cadastrados). `POST /api/auth/reset-password {email, code,
  newPassword}` troca a senha e queima o código. O código é hasheado no banco, vale por
  `app.password-reset.code-ttl-minutes`, é de uso único, tem limite de tentativas e emitir um novo
  invalida os anteriores.
```

- [ ] **Step 2: Atualizar a spec da tela**

Em `password-reset.md`, na seção "Dados & contrato", trocar a descrição do `ResetPasswordScreen` por:

```markdown
- `ResetPasswordScreen` (aberta a partir da tela anterior, recebendo o e-mail):
  `POST /api/auth/reset-password {email, code, newPassword}` → `{success:true}` ou erro de código
  inválido/expirado/tentativas esgotadas. O código de 6 dígitos é digitado nesta mesma tela, acima
  dos campos de senha — não vem por URL.
```

E, em "Layout / campos", trocar a linha do redefinir por:

```markdown
- Redefinir senha: código recebido por e-mail + nova senha + confirmar senha.
```

- [ ] **Step 3: Conferir que nenhuma menção a link sobrou**

```bash
grep -rn "link de redefini\|token na URL" smartboarding-api/docs/spec.md smartboarding_app/docs/specs/autenticacao/password-reset.md
```

Esperado: nenhuma saída.

- [ ] **Step 4: Commit (após aprovação do autor)**

```bash
git add smartboarding-api/docs/spec.md smartboarding_app/docs/specs/autenticacao/password-reset.md
git commit -m "docs: RN22 passa a descrever codigo de 6 digitos, nao link"
```

---

## Fechamento da PR

- [ ] Rodar o gate inteiro dos dois lados: `./mvnw clean verify` e `dart format . && flutter analyze && flutter test`.
- [ ] Conferir que nenhum arquivo tocado passa de 300 linhas.
- [ ] Preencher o template de PR (inclusive a tabela de cobertura) e abrir **somente após aprovação do autor**, com base na `main`.
