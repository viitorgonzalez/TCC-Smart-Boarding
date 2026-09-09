# Perfil e status do aluno — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tocar num aluno abre um card com o perfil breve dele, onde o admin ativa ou desativa a conta — e cada mudança fica registrada com qual admin fez e quando.

**Architecture:** DTO próprio e estreito para o card (não reusa `UserResponse`, que carrega e-mail e endereço), endpoint de status que grava numa tabela de log, e reativação de rota fechando o buraco do soft-delete sem volta.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · Flyway · Postgres 16 · JUnit 5 + Mockito + AssertJ — Flutter/Dart 3.11 · Provider · Dio.

**Spec:** `docs/superpowers/specs/2026-09-08-hardening-pre-producao-design.md` (§4.3)

**Escopo desta PR:** a 3ª das 5 da spec §6.

## Global Constraints

- Branch: `feature/hardening-pre-producao`. Migration nova é a **V21**.
- Nenhum arquivo tocado passa de **300 linhas**. Comentário explica o **porquê**.
- Commit convencional, **sem** `Co-Authored-By` de IA.
- **Não** commitar, pushar ou abrir PR sem aprovação explícita do autor.
- **O card não expõe dado credencial.** Decisão desta PR: o DTO manda `fullName`, `course`, `institution`, `isActive`, presenças recentes e o log — e **omite e-mail, endereço, telefone e data de nascimento**. Não ir por `UserResponse` é intencional: ele carrega tudo isso, e "não renderizar no app" protege menos do que "não mandar pela rede".

## File Structure

**API**

| Arquivo | Responsabilidade |
|---|---|
| `db/migration/V21__user_status_log.sql` | tabela de auditoria |
| `domain/user/entity/UserStatusLog.java` | registro da mudança |
| `domain/user/port/in/ManageUserStatusUseCase.java` | ativar/desativar |
| `domain/user/port/out/UserStatusLogRepositoryPort.java` | persistência do log |
| `infrastructure/persistence/user/UserStatusLogJpaRepository.java` | Spring Data |
| `infrastructure/persistence/user/UserStatusLogRepositoryAdapter.java` | adapter |
| `application/user/UserStatusUseCaseImpl.java` | a regra + o log |
| `infrastructure/web/user/dto/StudentProfileResponse.java` | o card, sem dado credencial |
| `infrastructure/web/user/dto/UpdateUserStatusRequest.java` | `{active}` |
| `infrastructure/web/user/UserController.java` *(modificar)* | `PATCH /{id}/status`, `GET /{id}/profile` |
| `infrastructure/web/route/dto/UpdateRouteRequest.java` *(modificar)* | aceita `isActive` |
| `application/route/RouteUseCaseImpl.java` *(modificar)* | aplica `isActive` |
| `infrastructure/config/SecurityConfig.java` *(modificar)* | rotas ADMIN |
| `src/test/.../application/user/UserStatusUseCaseImplTest.java` | testes |

**App**

| Arquivo | Responsabilidade |
|---|---|
| `lib/features/users/models/student_profile_model.dart` | perfil + log |
| `lib/features/users/services/user_service.dart` *(modificar)* | perfil e status |
| `lib/features/users/widgets/student_profile_card.dart` | o card |
| `lib/features/users/screens/route_students_screen.dart` *(modificar)* | toque abre o card |
| `lib/features/lists/screens/admin_list_entries_screen.dart` *(modificar)* | idem, na lista |
| `test/widget/student_profile_card_test.dart` | o que o card mostra e o que esconde |

---

### Task 1: Log de auditoria do status

**Files:**
- Create: `db/migration/V21__user_status_log.sql`
- Create: `.../domain/user/entity/UserStatusLog.java`
- Create: `.../domain/user/port/out/UserStatusLogRepositoryPort.java`
- Create: `.../infrastructure/persistence/user/UserStatusLogJpaRepository.java`
- Create: `.../infrastructure/persistence/user/UserStatusLogRepositoryAdapter.java`

**Interfaces:**
- Produces: `UserStatusLog` · `UserStatusLogRepositoryPort.save(UserStatusLog)`, `.findAllByUserId(UUID)`.

- [ ] **Step 1: Migration**

```sql
-- Ativar/desativar aluno deixa rastro: quem fez e quando. Sem isso, conta
-- desativada vira misterio -- ninguem sabe se foi engano ou decisao.
CREATE TABLE user_status_log (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    admin_id   UUID        REFERENCES users(id) ON DELETE SET NULL,
    action     VARCHAR(20) NOT NULL,
    created_at TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_status_log_user ON user_status_log(user_id);
```

- [ ] **Step 2: Entidade**

```java
package com.smartboarding.smartboarding_api.domain.user.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_status_log")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserStatusLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /// Nulo só se o admin for removido depois — o registro sobrevive a ele.
    @Column(name = "admin_id")
    private UUID adminId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserStatusAction action;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
```

E o enum, em arquivo próprio `UserStatusAction.java`:

```java
package com.smartboarding.smartboarding_api.domain.user.entity;

public enum UserStatusAction {
    ACTIVATED, DEACTIVATED
}
```

- [ ] **Step 3: Porta, repositório e adapter**

Porta:

```java
package com.smartboarding.smartboarding_api.domain.user.port.out;

import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;

import java.util.List;
import java.util.UUID;

public interface UserStatusLogRepositoryPort {
    UserStatusLog save(UserStatusLog log);

    List<UserStatusLog> findAllByUserId(UUID userId);
}
```

Repositório Spring Data com `findAllByUserIdOrderByCreatedAtDesc(UUID)`, e adapter `@Component` delegando — mesmo formato do `WarningRepositoryAdapter`, que já existe no repo e serve de referência de estilo.

- [ ] **Step 4: Verificar o schema**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress verify
```

Esperado: `BUILD SUCCESS`.

- [ ] **Step 5: Commit (após aprovação do autor)**

```bash
git commit -m "feat(api): tabela de auditoria de status do aluno"
```

---

### Task 2: Ativar e desativar com registro

**Files:**
- Create: `.../domain/user/port/in/ManageUserStatusUseCase.java`
- Create: `.../application/user/UserStatusUseCaseImpl.java`
- Test: `src/test/.../application/user/UserStatusUseCaseImplTest.java`

**Interfaces:**
- Consumes: `UserRepositoryPort.findById/save`, `UserStatusLogRepositoryPort` (Task 1), `Clock`.
- Produces: `ManageUserStatusUseCase.setActive(UUID userId, boolean active, UUID adminId)` → `User`; `.history(UUID userId)` → `List<UserStatusLog>`.

- [ ] **Step 1: Porta**

```java
package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;

import java.util.List;
import java.util.UUID;

public interface ManageUserStatusUseCase {
    /// Toda mudanca deixa registro de quem fez e quando -- e por isso que
    /// [adminId] e obrigatorio no caminho, mesmo sendo anulavel na tabela.
    User setActive(UUID userId, boolean active, UUID adminId);

    List<UserStatusLog> history(UUID userId);
}
```

- [ ] **Step 2: Testes que falham**

```java
package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.*;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserStatusLogRepositoryPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UserStatusUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 8, 14, 0);
    private static final UUID STUDENT = UUID.randomUUID();
    private static final UUID ADMIN = UUID.randomUUID();

    @Mock UserRepositoryPort userRepository;
    @Mock UserStatusLogRepositoryPort logRepository;

    private UserStatusUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new UserStatusUseCaseImpl(userRepository, logRepository,
                Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE));
        when(userRepository.findById(STUDENT)).thenReturn(Optional.of(
                User.builder().id(STUDENT).fullName("Ana Oliveira").isActive(true).build()));
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(logRepository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void desativarGravaLogComAdminEInstante() {
        useCase.setActive(STUDENT, false, ADMIN);

        ArgumentCaptor<UserStatusLog> captor = ArgumentCaptor.forClass(UserStatusLog.class);
        verify(logRepository).save(captor.capture());
        UserStatusLog log = captor.getValue();

        assertThat(log.getUserId()).isEqualTo(STUDENT);
        assertThat(log.getAdminId()).isEqualTo(ADMIN);
        assertThat(log.getAction()).isEqualTo(UserStatusAction.DEACTIVATED);
        assertThat(log.getCreatedAt()).isEqualTo(NOW);
    }

    @Test
    void desativarDesligaAConta() {
        User saved = useCase.setActive(STUDENT, false, ADMIN);

        assertThat(saved.isActive()).isFalse();
    }

    @Test
    void reativarGravaAcaoDeAtivacao() {
        when(userRepository.findById(STUDENT)).thenReturn(Optional.of(
                User.builder().id(STUDENT).fullName("Ana Oliveira").isActive(false).build()));

        useCase.setActive(STUDENT, true, ADMIN);

        ArgumentCaptor<UserStatusLog> captor = ArgumentCaptor.forClass(UserStatusLog.class);
        verify(logRepository).save(captor.capture());
        assertThat(captor.getValue().getAction()).isEqualTo(UserStatusAction.ACTIVATED);
    }

    @Test
    void mudancaSemEfeitoNaoPoluiOLog() {
        // Ja esta ativo: registrar "ativou" de novo encheria o historico de ruido
        // e faria parecer que houve acao.
        useCase.setActive(STUDENT, true, ADMIN);

        verify(logRepository, never()).save(any());
        verify(userRepository, never()).save(any());
    }
}
```

- [ ] **Step 3: Rodar e confirmar que falha**

```bash
cd smartboarding-api && ./mvnw -B --no-transfer-progress test -Dtest=UserStatusUseCaseImplTest
```

- [ ] **Step 4: Implementar**

```java
package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.*;
import com.smartboarding.smartboarding_api.domain.user.port.in.ManageUserStatusUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserStatusLogRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class UserStatusUseCaseImpl implements ManageUserStatusUseCase {

    private final UserRepositoryPort userRepository;
    private final UserStatusLogRepositoryPort logRepository;
    private final Clock clock;

    public UserStatusUseCaseImpl(UserRepositoryPort userRepository,
                                 UserStatusLogRepositoryPort logRepository,
                                 Clock clock) {
        this.userRepository = userRepository;
        this.logRepository = logRepository;
        this.clock = clock;
    }

    @Override
    @Transactional
    public User setActive(UUID userId, boolean active, UUID adminId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        // Sem mudanca real nao ha o que registrar -- log cheio de repeticao
        // esconde a acao que importa.
        if (user.isActive() == active) {
            return user;
        }

        user.setActive(active);
        User saved = userRepository.save(user);

        logRepository.save(UserStatusLog.builder()
                .userId(userId)
                .adminId(adminId)
                .action(active ? UserStatusAction.ACTIVATED : UserStatusAction.DEACTIVATED)
                .createdAt(LocalDateTime.now(clock))
                .build());

        return saved;
    }

    @Override
    public List<UserStatusLog> history(UUID userId) {
        return logRepository.findAllByUserId(userId);
    }
}
```

- [ ] **Step 5: Rodar e confirmar que passa**

Esperado: `Tests run: 4, Failures: 0, Errors: 0`.

- [ ] **Step 6: Commit (após aprovação do autor)**

```bash
git commit -m "feat(api): ativar e desativar aluno com registro de autoria"
```

---

### Task 3: Perfil breve e endpoints

**Files:**
- Create: `.../infrastructure/web/user/dto/StudentProfileResponse.java`
- Create: `.../infrastructure/web/user/dto/UpdateUserStatusRequest.java`
- Modify: `.../infrastructure/web/user/UserController.java`
- Modify: `.../infrastructure/config/SecurityConfig.java`

**Interfaces:**
- Consumes: `ManageUserStatusUseCase` (Task 2), `ListEntryRepositoryPort.findAttendanceSince(UUID, LocalDate)`, `InstitutionRepositoryPort`.
- Produces: `GET /api/users/{id}/profile` → `StudentProfileResponse`; `PATCH /api/users/{id}/status {active}` → `StudentProfileResponse`.

- [ ] **Step 1: DTO do perfil**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/// Perfil breve pro card do admin. Nao carrega e-mail, endereco, telefone nem
/// data de nascimento: o card e pra conferencia rapida, e o que nao trafega nao
/// vaza.
public record StudentProfileResponse(
        UUID id,
        String fullName,
        String course,
        String institution,
        boolean isActive,
        List<LocalDate> recentAttendance,
        List<StatusChange> statusHistory
) {
    public record StatusChange(String action, String adminName, LocalDateTime at) {}
}
```

- [ ] **Step 2: DTO de entrada**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.NotNull;

public record UpdateUserStatusRequest(@NotNull Boolean active) {}
```

- [ ] **Step 3: Endpoints no `UserController`**

Injetar `ManageUserStatusUseCase` e montar o `StudentProfileResponse` a partir do usuário, das presenças dos últimos 6 meses e do histórico. O `adminName` sai de um `findById` no id do log — um mapa único para não fazer N+1 quando o histórico tiver várias linhas.

O `PATCH` extrai o admin autenticado do `Authentication` (mesmo padrão do `extractUserId` que já existe no `ListController`) e repassa como `adminId`.

- [ ] **Step 4: Regras de acesso**

```java
                        .requestMatchers(HttpMethod.GET, "/api/users/{id}/profile").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/users/{id}/status").hasRole("ADMIN")
```

- [ ] **Step 5: Exercitar de verdade**

```bash
curl -s -X PATCH localhost:8080/api/users/$SID/status -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{"active":false}' | head -c 300
curl -s localhost:8080/api/users/$SID/profile -H "Authorization: Bearer $TOKEN" | head -c 400
```

Esperado: o perfil traz `statusHistory` com uma entrada nomeando o admin e o instante — e **não** traz `email`, `phone` nem `address`. Conferir isso explicitamente: campo credencial na resposta é falha desta PR.

Repetir o `PATCH` com o mesmo valor e confirmar que o histórico **não** cresce.

- [ ] **Step 6: Commit (após aprovação do autor)**

```bash
git commit -m "feat(api): perfil breve do aluno e endpoint de status"
```

---

### Task 4: Reativação de rota

Fecha o buraco: hoje `DELETE /api/routes/{id}` desativa por soft-delete e não existe caminho de volta.

**Files:**
- Modify: `.../infrastructure/web/route/dto/UpdateRouteRequest.java`
- Modify: `.../application/route/RouteUseCaseImpl.java`
- Modify: `.../infrastructure/web/route/RouteController.java`

- [ ] **Step 1: Aceitar `isActive` no request**

Acrescentar `Boolean isActive` ao record (anulável: nulo mantém como está, coerente com o resto do PATCH).

- [ ] **Step 2: Aplicar no use case**

Em `execute(UUID id, Route route)`, depois dos horários:

```java
        // Nulo mantem o estado atual: o PATCH e parcial. Sem isto, rota
        // desativada pelo DELETE nao teria caminho de volta.
        if (route.getIsActive() != null) {
            existing.setActive(route.getIsActive());
        }
```

> `Route.isActive` é `boolean` primitivo na entidade. Para distinguir "não informado" de "false", carregue o valor do request numa variável `Boolean` local no controller e passe adiante — não troque o tipo da entidade.

- [ ] **Step 3: Repassar no controller**

No `update`, incluir `isActive` ao montar o `Route` de entrada.

- [ ] **Step 4: Exercitar**

```bash
curl -s -X DELETE localhost:8080/api/routes/$RID -H "Authorization: Bearer $TOKEN" -o /dev/null -w "%{http_code}\n"
curl -s -X PATCH localhost:8080/api/routes/$RID -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{"name":"Rota Universitária de Formiga","isActive":true}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['isActive'])"
```

Esperado: `true` — a rota voltou.

- [ ] **Step 5: Commit (após aprovação do autor)**

```bash
git commit -m "fix(api): rota desativada volta a ficar ativa"
```

---

### Task 5: Card no app

**Files:**
- Create: `lib/features/users/models/student_profile_model.dart`
- Modify: `lib/features/users/services/user_service.dart`
- Create: `lib/features/users/widgets/student_profile_card.dart`
- Modify: `lib/features/users/screens/route_students_screen.dart`
- Modify: `lib/features/lists/screens/admin_list_entries_screen.dart`
- Test: `test/widget/student_profile_card_test.dart`

- [ ] **Step 1: Model**

`StudentProfile` com `id`, `fullName`, `course`, `institution`, `isActive`, `recentAttendance` (lista de datas) e `statusHistory` (lista de `StatusChange` com `action`, `adminName`, `at`), todos com `fromJson`. Espelha o DTO da Task 3 — **sem** campos de e-mail ou endereço.

- [ ] **Step 2: Service**

```dart
  Future<StudentProfile> getProfile(String userId) async {
    final response = await _dio.get('/api/users/$userId/profile');
    return StudentProfile.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StudentProfile> setActive(String userId, bool active) async {
    final response = await _dio.patch(
      '/api/users/$userId/status',
      data: {'active': active},
    );
    return StudentProfile.fromJson(response.data['data'] as Map<String, dynamic>);
  }
```

- [ ] **Step 3: Teste do card (falha primeiro)**

O teste mais importante desta PR é o que garante o que **não** aparece:

```dart
  testWidgets('card não mostra e-mail nem endereço', (tester) async {
    await tester.pumpWidget(wrap(StudentProfileCard(profile: perfil)));
    await tester.pumpAndSettle();

    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('Rua'), findsNothing);
  });

  testWidgets('card mostra quem mudou o status e quando', (tester) async {
    await tester.pumpWidget(wrap(StudentProfileCard(profile: perfilComHistorico)));
    await tester.pumpAndSettle();

    expect(find.textContaining('System Administrator'), findsOneWidget);
  });
```

- [ ] **Step 4: Escrever o card**

`StudentProfileCard` como `AppCard`: avatar de iniciais, nome, curso e instituição, `StatusPill` de ativo/inativo, `Switch` para alternar, presenças recentes em linha, e o histórico abaixo no formato "Desativado por Fulano · 08/09/2026 14:00". Abre via `showModalBottomSheet` a partir das duas telas.

- [ ] **Step 5: Ligar nas duas telas**

Em `route_students_screen.dart` e `admin_list_entries_screen.dart`, o toque no aluno abre o card.

- [ ] **Step 6: Gate e commit (após aprovação do autor)**

```bash
cd smartboarding_app && dart format . && flutter analyze && flutter test
git commit -m "feat(app): card de perfil do aluno com ativar/desativar"
```

---

## Fechamento da PR

- [ ] Gate dos dois lados verde.
- [ ] Conferido na resposta da API que o perfil **não** carrega e-mail, telefone, endereço nem data de nascimento.
- [ ] Nenhum arquivo tocado acima de 300 linhas.
- [ ] PR aberta **somente após aprovação do autor**.
