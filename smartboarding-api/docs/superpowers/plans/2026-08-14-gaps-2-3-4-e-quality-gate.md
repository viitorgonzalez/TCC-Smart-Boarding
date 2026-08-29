# Gaps 2/3/4 + Quality Gate de Cobertura (Backend) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar os três gaps documentados em `docs/spec.md` §7 (notificação de saída do motorista,
broadcast de lista aberta, perfil estendido + expiração de conta) e ligar um quality gate de
cobertura de teste (JaCoCo, ratchet) na CI — mantendo a API compilando e os testes verdes a cada
passo.

**Architecture:** Arquitetura hexagonal já existente (`domain/application/infrastructure`, ver
`docs/spec.md` §4.1). Cada gap segue o padrão já em uso: `*UseCase` (port `in`) →
`*UseCaseImpl` (`application/<contexto>`) → `*Controller` (`infrastructure/web/<contexto>`).
Nenhuma migration nova — todas as colunas do Gap 4 já existem em `V1__initial_schema.sql`.

**Tech Stack:** Java 21, Spring Boot 4.0.5, Maven, Spring Security (JWT), JPA/Hibernate,
Postgres 16/Flyway, JUnit 5 + Mockito (a adicionar como dependência de teste), JaCoCo (novo).

## Global Constraints

- **Não editar migrations existentes.** Gap 4 não precisa de `V3__...` — as colunas já existem.
  Se algum ajuste de schema aparecer durante a implementação, migration nova, nunca editar V1/V2.
- **Resposta padrão:** sucesso `{ "data": ... }` (`ApiResponse`), erro `{ "code": "...", "error": "..." }`
  (`GlobalExceptionHandler`). Novos erros seguem o mesmo padrão — não inventar formato.
- **Pacotes hexagonais** — não criar `Controllers/`/`Services/` capitalizados.
- **Contrato já fechado** — não reabrir discussão sobre os payloads dos Gaps 2/3/4, estão em
  `docs/spec.md` §6/§7. Só implementar.
- **`expiryDate = null` → nunca expira** (RN12). Toda checagem de expiração deve tratar null como
  "não expira", nunca como "já expirou".

---

### Task 1: Gap 2 — Notificação de saída direcionada (motorista)

**Files:**
- Create: `domain/list/port/in/NotifyDepartureUseCase.java`
- Modify: `application/list/ListUseCaseImpl.java` (ou nova classe `application/list/NotifyDepartureUseCaseImpl.java`, seguir o que já existe pro contexto `list`)
- Modify: `infrastructure/web/list/ListController.java` — novo endpoint
- Modify: `infrastructure/web/list/dto/` — request/response se necessário (reaproveitar `ApiResponse`)
- Modify: `infrastructure/config/SecurityConfig.java` — regra de acesso do novo path
- Create: `src/test/java/.../application/list/NotifyDepartureUseCaseImplTest.java`

**Interfaces:**
```
POST /api/lists/{id}/notifications/departure   · DRIVER, ADMIN
Request (opcional): { "title"?: string, "body"?: string }
Response 200: { "data": { "success": true, "notified": <int> } }
```

- [ ] **Step 1: Implementar `NotifyDepartureUseCase`**
  - Busca `list_entries` com `daily_list_id={id}` e `is_active=true`.
  - Resolve `device_tokens` dos usuários encontrados.
  - Envia FCM em loop, reaproveitando `SendToUserUseCase` (já usado em `ListUseCaseImpl.notifyEnrollment`) — best-effort, falha de envio individual não aborta o loop nem propaga erro.
  - Funciona independente de `DailyList.status` (`OPEN` ou `CLOSED`) — RN nova, mas já documentada.
  - Sem inscritos ativos → sucesso com `notified: 0` (não é erro).
  - Título/corpo default se omitido: usar o texto sugerido em `docs/spec.md` §7 Gap 2 ("Ônibus saindo!" / mensagem de embarque).

- [ ] **Step 2: Endpoint no `ListController`**
  - `POST /api/lists/{id}/notifications/departure`.
  - `404` se a lista não existir (mesmo padrão de `GET /api/lists/{id}`).

- [ ] **Step 3: `SecurityConfig` — liberar `DRIVER` e `ADMIN`**
  - Novo `.requestMatchers(HttpMethod.POST, "/api/lists/*/notifications/departure").hasAnyRole("DRIVER", "ADMIN")`.
  - Adicionar **antes** da regra genérica `.anyRequest().authenticated()` (ordem de matcher no Spring Security importa).

- [ ] **Step 4: Unit test do use case**
  - Mock do repositório de `ListEntry`/`DeviceToken` e do `SendToUserUseCase`.
  - Cenários: lista com N inscritos ativos → `notified: N`; lista sem inscritos → `notified: 0`; lista `CLOSED` → ainda funciona; falha de envio de 1 device não aborta os demais.

---

### Task 2: Gap 3 — Broadcast automático de "lista aberta"

**Files:**
- Modify: `application/list/SchedulerUseCaseImpl.java` (método `open()`)
- Modify (ou criar): `src/test/java/.../application/list/SchedulerUseCaseImplTest.java`

- [ ] **Step 1: Broadcast dentro de `open()`**
  - Depois de criar as `DailyList` do dia (mesmo padrão idempotente de RN1), se **pelo menos uma**
    lista foi criada nesta execução, chamar `SendBroadcastUseCase` com a mensagem:
    `"A lista de embarque de hoje já está disponível! Inscreva-se até as 16h."`
  - Best-effort — falha no broadcast é logada, não interrompe a abertura das listas (mesmo padrão
    de `close()`).
  - Dia sem rota ativa (nenhuma lista criada) → **não** dispara broadcast.

- [ ] **Step 2: Unit test**
  - Mock de `SendBroadcastUseCase`. Cenários: 1+ lista criada → broadcast chamado 1x; 0 listas
    criadas (já existiam todas, idempotência de RN1) → broadcast não chamado; falha do broadcast
    não impede `open()` de retornar normalmente.

---

### Task 3: Gap 4 — Perfil estendido no cadastro

**Files:**
- Modify: `infrastructure/web/user/dto/RegisterRequest.java`
- Modify: `application/user/AuthUseCaseImpl.java` (método de registro/`execute`)
- Modify (se necessário): `infrastructure/web/user/dto/UserResponse.java` — já retorna os campos (confirmar sem alteração)
- Modify: `src/test/java/.../application/user/AuthUseCaseImplTest.java` (criar se não existir)

- [ ] **Step 1: Estender `RegisterRequest`**
  - Campos novos, todos **opcionais** (sem `@NotNull`/`@NotBlank`), qualquer role pode enviá-los
    (decisão em `docs/spec.md` §0 — sem validação cruzada role↔campo no backend):
    ```java
    java.time.LocalDate birthDate,
    String course,
    String institution,
    String phone,
    String address,
    java.time.LocalDate expiryDate
    ```
  - Validação leve: `@Size(max = 100)` em `course`/`institution`, `@Size(max = 20)` em `phone`
    (espelhar `Column(length=...)` do `User` entity) — sem regex de formato de telefone (fora de
    escopo, não decidido).

- [ ] **Step 2: Persistir no `AuthUseCaseImpl`**
  - Repassar os novos campos pro `User.builder()` na criação.

- [ ] **Step 3: Unit test**
  - Registro só com campos obrigatórios → campos opcionais ficam `null`, sem erro.
  - Registro com todos os campos → persistidos e retornados em `UserResponse`.
  - Registro de `DRIVER`/`ADMIN` com os campos preenchidos → aceito sem erro (API não restringe por role).

---

### Task 4: RN12 — Enforcement de `expiryDate` (login + entrada na lista)

**Files:**
- Modify: `application/user/AuthUseCaseImpl.java` (método de login)
- Modify: `application/list/ListUseCaseImpl.java` (método `add()`)
- Modify: `shared/exception/` — nova exception ou reaproveitar `UnauthorizedException`/`BadRequestException` com `code=ACCOUNT_EXPIRED`
- Modify: `infrastructure/web/common/GlobalExceptionHandler.java` (se precisar de mapeamento novo)
- Create/modify: testes de `AuthUseCaseImplTest` e `ListUseCaseImplTest`

- [ ] **Step 1: Checagem no login**
  - Depois de validar credenciais e **antes** de emitir o JWT: se `user.getExpiryDate() != null && user.getExpiryDate().isBefore(LocalDate.now())` → lançar exceção mapeada pra `401 ACCOUNT_EXPIRED`.
  - `expiryDate = null` → não bloqueia (RN12).

- [ ] **Step 2: Checagem em `ListUseCaseImpl.add()`**
  - Mesma regra, mapeada pra `403 ACCOUNT_EXPIRED` (já autenticado, mas ação proibida — `403`, não `401`).
  - Motivo (documentado em RN12): token de 1h emitido antes da expiração continua válido; sem essa segunda checagem a conta expirada ainda conseguiria embarcar.

- [ ] **Step 3: Unit tests**
  - Login: `expiryDate` no passado → `401 ACCOUNT_EXPIRED`; no futuro → login normal; `null` → login normal.
  - `add()`: mesmos três cenários, verificando `403 ACCOUNT_EXPIRED` no caso expirado.

---

### Task 5: Quality gate de cobertura (JaCoCo + CI)

**Files:**
- Modify: `pom.xml` — plugin `jacoco-maven-plugin`
- Create: `.coverage-baseline` (raiz de `smartboarding-api/`)
- Modify: `../.github/workflows/ci.yml` — job `api`

- [ ] **Step 1: Adicionar JaCoCo ao `pom.xml`**
  ```xml
  <plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.12</version>
    <executions>
      <execution>
        <goals><goal>prepare-agent</goal></goals>
      </execution>
      <execution>
        <id>report</id>
        <phase>test</phase>
        <goals><goal>report</goal></goals>
      </execution>
    </executions>
  </plugin>
  ```
  - `phase=test` garante que o relatório (`target/site/jacoco/jacoco.csv`) sai do mesmo `./mvnw test` que a CI já roda — sem step novo de build.

- [ ] **Step 2: Medir e commitar a baseline inicial**
  - Rodar `./mvnw test` localmente (com Postgres do `docker compose up -d` de pé) **depois** das
    Tasks 1–4 estarem prontas (a baseline deve refletir o estado com os novos testes já somados,
    não o estado pré-gaps).
  - Calcular `%` = `LINE_COVERED / (LINE_COVERED + LINE_MISSED) * 100` a partir de
    `target/site/jacoco/jacoco.csv` (somar todas as linhas do CSV, não usar só uma classe).
  - Commitar o número em `smartboarding-api/.coverage-baseline` (uma linha, ex.: `18.4`).

- [ ] **Step 3: Step de CI que aplica o ratchet**
  - Depois do step "Testes" no job `api` do `ci.yml`, adicionar:
    ```yaml
    - name: Quality gate de cobertura
      run: |
        actual=$(awk -F',' 'NR>1 {covered+=$6; missed+=$5} END {printf "%.1f", covered*100/(covered+missed)}' target/site/jacoco/jacoco.csv)
        baseline=$(cat .coverage-baseline)
        echo "cobertura atual: ${actual}% · baseline: ${baseline}%"
        awk -v a="$actual" -v b="$baseline" 'BEGIN { if (a+0 < b+0) { print "regressão de cobertura"; exit 1 } }'
        awk -v a="$actual" -v b="$baseline" 'BEGIN { if (a+0 > b+0.5) { print "cobertura subiu mas .coverage-baseline não foi atualizado — setar para " a; exit 1 } }'
    ```
    (colunas do `jacoco.csv`: confirmar índice exato de `LINE_MISSED`/`LINE_COVERED` no header antes de fixar `$5`/`$6` — o awk acima é o esqueleto, não copiar sem validar contra um CSV real gerado localmente.)
  - Falha do step bloqueia o merge (branch protection já cobre isso desde que o job `api` seja required — confirmar nas configurações do repo, fora do escopo deste plano).

- [ ] **Step 4: Atualizar `docs/spec.md` se o mecanismo mudar**
  - Se o step 3 acima mudar de forma (ex.: trocar awk por script Python), refletir a mudança em
    `docs/spec.md` §8 — a spec descreve o mecanismo real, não um esqueleto.

---

## Ordem recomendada

Tasks 1–4 são independentes entre si (contextos diferentes: `list`, `list`/scheduler, `user`,
`user`+`list`) — podem ser feitas em qualquer ordem ou em paralelo. **Task 5 vem por último**,
porque a baseline inicial deve refletir a cobertura já incluindo os testes novos das Tasks 1–4.
