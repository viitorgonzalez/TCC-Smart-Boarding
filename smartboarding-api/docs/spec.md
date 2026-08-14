# SmartBoarding API — Design & Regras de Negócio

> Status: aprovado — documenta o estado **já implementado** em `fix/project-setup`.
> Data: 2026-08-14
> Escopo deste documento: **backend** (`smartboarding-api/`). É uma spec de catch-up — o
> código já existe; este documento registra o contrato e as decisões que ele encarna, porque
> `PLAN.md`/`AGENTS.md` (removidos) descreviam um estado pré-implementação que não reflete mais
> a realidade. Espelha o formato e o precedente de `smartboarding_app/docs/spec.md`.

---

## 0. Registro de Decisões

Decisões tomadas durante a sessão que gerou este documento (2026-08-14) — com o motivo, para não
precisar re-discutir depois.

| Decisão | Escolha | Motivo |
|---|---|---|
| Formato da spec de backend | Documento único (`docs/spec.md`), não uma spec por domínio | Domínio ainda pequeno o suficiente pra caber coeso num arquivo só — mesma lógica do `spec.md` do Flutter |
| Destino de `PLAN.md`/`AGENTS.md` | Apagados | Descreviam um estado pré-implementação (migrations V3–V7, pacotes flat) que não existe mais; mantê-los só confundiria quem lesse depois. Este `spec.md` os substitui |
| Gaps 2 e 3 (endpoint de notificação de saída do motorista; broadcast de lista aberta) | Só documentados nesta rodada — não implementados agora | Já têm contrato claro e o Flutter já depende deles (`driver_service.dart`), mas a implementação fica pra uma demanda `/do` separada |
| Convenção de pacotes documentada | Corrigida em `smartboarding-api/CLAUDE.md` e `personal-harness/docs/repos.md` pra refletir a arquitetura hexagonal real | Os dois arquivos descreviam pacotes flat capitalizados (`Models/`, `Controllers/`...) que nunca corresponderam ao código desde a migração pra `domain/application/infrastructure` |

> Decisão revista depois **não se apaga**: risca a antiga e anota a revisão com data e motivo.

---

## 1. Visão Geral

### Problema

O controle de embarque no ônibus universitário (Unifor) era feito manualmente por um grupo de
WhatsApp: alunos escreviam o próprio nome numa lista, o grupo "fechava" por mensagem humana às
16h, o tamanho do veículo era decidido contando nomes manualmente, e não havia aviso automático
de saída do ônibus. Sujeito a erro (duplicatas, fechamento atrasado) e não escalável.

### Objetivo do backend

1. Persistir e servir listas diárias de embarque com abertura/fechamento **automáticos por
   horário**, sem depender de um humano lembrar de fechar o grupo.
2. Contar inscritos em tempo real (`COUNT WHERE is_active = true`), sem digitação manual.
3. Disparar notificações push (FCM) nos momentos certos, e dar ao motorista e ao admin os
   endpoints pra ação manual (saída do ônibus, broadcast).
4. Expor um contrato estável o suficiente pro app Flutter consumir sem acoplamento a detalhes de
   persistência.

### Fora de escopo (por enquanto)

- Múltiplas rotas simultâneas ativas de verdade (suportado pelo schema, mas o uso real é uma
  rota principal).
- Autocadastro de usuários — toda conta nasce de `POST /api/auth/register` (ADMIN-only).
- Pagamento/cobrança.
- Rastreamento em tempo real (GPS) do ônibus.
- Perfil estendido de usuário no cadastro (curso, instituição, telefone, endereço, data de
  nascimento, data de expiração) — a coluna existe no schema (`users`) e `UserResponse` já
  retorna esses campos, mas `POST /api/auth/register` **não os aceita** (ver §7, Gap 4) e o
  formulário de criação de usuário no Flutter também não os coleta ainda.

---

## 2. Papéis e Permissões

Fonte de verdade: `SecurityConfig.java` (`infrastructure/config/`).

| Papel | Pode | Não pode |
|---|---|---|
| **Público** (sem token) | `POST /api/auth/login`, `GET /api/routes`, `GET /api/routes/{id}` | Tudo o resto |
| **`STUDENT`** | Ver lista(s) do dia, entrar/sair da própria inscrição, ver detalhe de rota, registrar/remover o próprio device token | Criar/editar rotas, gerenciar usuários, ver relatórios, disparar notificações |
| **`DRIVER`** | Mesmo acesso de leitura que `STUDENT` a listas/rotas; **não** tem hoje um endpoint próprio de notificação de saída (ver Gap 2) | Gerenciar rotas, usuários ou relatórios |
| **`ADMIN`** | Tudo: CRUD de rotas, `POST /api/auth/register`, listar usuários, ver relatórios, `POST /api/notifications/broadcast` | — |

⚠️ **Observação de segurança a validar**: `POST/DELETE /api/lists/{id}/entries` cai na regra
genérica `.anyRequest().authenticated()` — **qualquer** papel autenticado (inclusive `ADMIN`
e `DRIVER`) pode entrar/sair de uma lista, não só `STUDENT`. O `PLAN.md` original propunha
restringir a `STUDENT`, mas isso nunca foi implementado na `SecurityConfig`. Não é
necessariamente um bug (pode ser intencional — motorista/admin também usam o ônibus), mas não
está decidido em nenhum doc. Fica registrado aqui como ponto em aberto, não como Gap formal.

---

## 3. Regras de Negócio

Numeradas pra referenciar de plano/teste/PR. Todas **já implementadas**, salvo indicação contrária.

- **RN1** — Lista diária abre automaticamente às **00:00** (seg–sex) para cada `Route` com
  `isActive=true`. Idempotente: se já existe `DailyList` para (rota, data), não recria
  (`existsByRouteIdAndDate`). — `SchedulerUseCaseImpl.open()`
- **RN2** — Lista diária fecha automaticamente às **16:00** (seg–sex): `status=CLOSED`,
  `closedAt=now()`, gera `Report` (snapshot dos inscritos ativos) e dispara broadcast FCM
  "Embarque confirmado". — `SchedulerUseCaseImpl.close()`
- **RN3** — Entrar/sair de uma lista só é permitido com `status=OPEN` — fora disso, `400
  LIST_CLOSED`. — `ListUseCaseImpl.add()`/`remove()`
- **RN4** — Uma inscrição por (usuário, lista) — `UNIQUE(user_id, daily_list_id)` no banco.
  Reentrar numa lista onde o usuário já tem `ListEntry` **reativa** o registro existente (não
  cria duplicata) e **não retorna 409** — mesmo se a inscrição já estiver ativa, o `POST`
  simplesmente atualiza o `tripType` e é idempotente. *(Isso diverge do `PLAN.md` original, que
  propunha 409 para reinscrição em entrada já ativa — o código implementado não faz isso.)*
- **RN5** — Sair da lista é soft-delete (`is_active=false`) — nunca `DELETE` físico.
- **RN6** — Cada inscrição tem um `tripType`: `ROUND_TRIP` (padrão) | `TO_CAMPUS` | `FROM_CAMPUS`
  — campo `list_entries.trip_type`, editável enquanto a lista estiver `OPEN` (reentrar com um
  `tripType` diferente atualiza o existente). **Não documentado em nenhum doc anterior** (nem
  `CONTEXT.md`, nem `spec.md` do Flutter) — é um conceito de domínio real no schema e na API que
  faltava registro.
- **RN7** — Ao entrar na lista (criação ou reativação), dispara notificação FCM individual de
  confirmação — best-effort: falha no envio é logada, não propaga erro pro cliente.
  — `ListUseCaseImpl.notifyEnrollment()`
- **RN8** — `Report` é gerado automaticamente no fechamento, é imutável (sem endpoint de edição)
  e só `ADMIN` acessa (`GET /api/reports`, paginado — default `size=20`, ordenado por
  `generatedAt DESC`; `GET /api/reports/{id}` com `snapshotData` completo).
- **RN9** — Nome de rota é único entre rotas ativas — `409 ROUTE_NAME_CONFLICT` na criação;
  duplicar nome exato na criação retorna `409 ROUTE_ALREADY_EXISTS`. Deletar rota é soft
  (`isActive=false`).
- **RN10** — E-mail de usuário é único — `409 EMAIL_ALREADY_EXISTS` no registro. Senha mínima de
  6 caracteres (`@Size(min = 6)` em `RegisterRequest`).
- **RN11** — Papel `DRIVER` existe no domínio (`Role.java`) desde a consolidação de migrations
  (12/08/2026, coluna `role` é `VARCHAR(20)` sem `CHECK`, validada na aplicação) — mas **não tem
  endpoint próprio**: hoje só enxerga os mesmos dados de leitura que `STUDENT` (ver Gap 2).

---

## 4. Arquitetura

### 4.1 Estrutura de pacotes (hexagonal / ports & adapters)

```
com.smartboarding.smartboarding_api/
├── domain/<contexto>/            # regra de negócio pura
│   ├── entity/                   # Route, DailyList, ListEntry, Report, DeviceToken, User, Role...
│   └── port/
│       ├── in/                   # *UseCase (interface) — o que o domínio oferece
│       └── out/                  # *RepositoryPort (interface) — o que o domínio precisa
├── application/<contexto>/       # *UseCaseImpl — implementação dos casos de uso
├── infrastructure/
│   ├── web/<contexto>/           # *Controller + dto/ (Request/Response)
│   │   └── common/               # GlobalExceptionHandler
│   └── config/                   # SecurityConfig, ...
└── shared/
    ├── exception/                 # AppException, NotFoundException, ConflictException,
    │                               # UnauthorizedException, BadRequestException
    └── web/                       # ApiResponse<T>
```

⚠️ **Isto substitui a convenção documentada anteriormente** (`Models/`, `Controllers/`,
`Services/`, `Repositories/`, `DTO/`, `Configs/`, `Enums/` capitalizados) em
`smartboarding-api/CLAUDE.md` e `personal-harness/docs/repos.md` — código real não usa essa
estrutura desde a migração pra arquitetura hexagonal (branch `feat/clean-architecture-persistence-layer`,
mergeada). Os dois arquivos foram corrigidos junto com esta spec.

Contextos (`<contexto>`): `user`, `route`, `list`, `report`, `notification`.

### 4.2 Persistência

- PostgreSQL 16, Flyway. Migrations consolidadas em **`V1__initial_schema.sql`** (DDL) +
  **`V2__seed_data.sql`** (dados de demo) — as antigas V1–V11 foram achatadas em 12/08/2026,
  antes de existir ambiente publicado. Daqui pra frente, mudança de schema = `V3+` nova, nunca
  edição das duas existentes.
- Tabelas: `users`, `routes`, `daily_lists`, `list_entries` (com `trip_type`, RN6),
  `reports`, `device_tokens`. Todas com PK `UUID` (`gen_random_uuid()`).

### 4.3 Autenticação

- JWT via `spring-security-oauth2-resource-server`, algoritmo **HS256**, expiração **1h**
  (`AuthUseCaseImpl.EXPIRY_SECONDS = 3600`), issuer `smartboarding-api`.
- Claim `scope` carrega o(s) role(s) do usuário; `JwtGrantedAuthoritiesConverter` prefixa
  `ROLE_` — é isso que `hasRole("ADMIN")` etc. checam na `SecurityConfig`.
- Senha: BCrypt (`BCryptPasswordEncoder`).
- Sessão stateless (`SessionCreationPolicy.STATELESS`), CSRF desabilitado (API pura, sem cookie).

### 4.4 Envelope de resposta

- Sucesso: `{ "data": <payload> }` — `ApiResponse.data(...)`. Operação sem payload de retorno:
  `{ "data": { "success": true } }` — `ApiResponse.success()`.
- Erro: `{ "code": "<CODIGO>", "error": "<mensagem>" }` — `GlobalExceptionHandler`.

### 4.5 Scheduler

- `@EnableScheduling` + `@Scheduled(cron = "...")` em `SchedulerUseCaseImpl`
  (`application/list/`). Dois jobs: `open()` (`0 0 0 * * MON-FRI`) e `close()`
  (`0 0 16 * * MON-FRI`). Sem execução aos fins de semana (cron `MON-FRI`).

---

## 5. Fluxos Principais

### Fluxo 1 — Estudante se inscreve na lista

```
1. Login → JWT (role no claim scope)
2. App registra device token → POST /api/devices/token
3. GET /api/lists/today → listas OPEN do dia
4. POST /api/lists/{id}/entries { tripType? } (default ROUND_TRIP)
5. Backend valida: lista OPEN? Se fechada → 400 LIST_CLOSED
6. Cria ou reativa ListEntry, notifica FCM individual (best-effort)
7. Resposta 201 com EntryResponse (id, userId, fullName, email, tripType, createdAt)
```

### Fluxo 2 — Fechamento automático (16:00, seg-sex)

```
1. SchedulerUseCaseImpl.close() dispara
2. Busca DailyList com status=OPEN e date=hoje
3. Por lista: status=CLOSED, closedAt=now(), gera Report (snapshot dos ativos)
4. Se houve pelo menos uma lista fechada: broadcast FCM "Embarque confirmado"
   (best-effort — falha é logada, não interrompe o fechamento)
```

### Fluxo 3 — Abertura automática (00:00, seg-sex)

```
1. SchedulerUseCaseImpl.open() dispara
2. Para cada Route.isActive=true sem DailyList(rota, hoje): cria DailyList(status=OPEN)
3. ⚠️ Não dispara broadcast — ver Gap 3 (§7)
```

### Fluxo 4 — Admin envia notificação manual

```
1. POST /api/notifications/broadcast { title, body } (ADMIN)
2. SendBroadcastUseCase → FCM pra todos os device_tokens registrados
```

### Fluxo 5 — Admin consulta relatórios

```
1. GET /api/reports?page=&size=&sort=generatedAt,desc (ADMIN) → paginado
2. GET /api/reports/{id} (ADMIN) → snapshotData completo (JSON dos inscritos no fechamento)
```

### Fluxo 6 — Motorista notifica saída (⚠️ Gap 2 — não implementado)

```
Fluxo pretendido (já esperado pelo Flutter, driver_service.dart):
1. DRIVER seleciona a lista/rota do dia
2. POST /api/lists/{id}/notifications/departure { title?, body? } (DRIVER, ADMIN)
3. Backend busca list_entries ativos da lista, resolve device_tokens, envia FCM (loop, não
   broadcast) independente do status da lista
4. Resposta: { "data": { "success": true, "notified": N } }
```

---

## 6. Contratos de API

> Fonte: código (`infrastructure/web/**/*Controller.java` + `dto/`), não memória. Divergiu?
> O código vence — corrija esta tabela no mesmo PR.

| Método | Path | Acesso | Request | Response (200/201) | Erros |
|---|---|---|---|---|---|
| POST | `/api/auth/login` | Público | `{email, password}` | `{token, fullName, role}` | `401` credenciais inválidas |
| POST | `/api/auth/register` | ADMIN | `{email, password≥6, role, fullName}` | `UserResponse` | `409 EMAIL_ALREADY_EXISTS`, `400 VALIDATION_ERROR` |
| GET | `/api/users` | ADMIN | — | `UserResponse[]` | — |
| GET | `/api/users/{id}` | ADMIN | — | `UserResponse` | `404` |
| POST | `/api/routes` | ADMIN | `{name, description?}` | `RouteResponse` | `409 ROUTE_ALREADY_EXISTS`/`ROUTE_NAME_CONFLICT` |
| GET | `/api/routes` | Público | — | `RouteResponse[]` (só ativas) | — |
| GET | `/api/routes/{id}` | Público | — | `RouteResponse` | `404` |
| PATCH | `/api/routes/{id}` | ADMIN | `{name, description?}` | `RouteResponse` | `404`, `409` (nome duplicado) |
| DELETE | `/api/routes/{id}` | ADMIN | — | `{success:true}` (soft-delete) | `404` |
| GET | `/api/lists/today` | Autenticado | — | `ListResponse[]` (com `enrolled`, `tripType` do usuário logado) | — |
| GET | `/api/lists/{id}` | Autenticado | — | `ListResponse` | `404` |
| POST | `/api/lists/{id}/entries` | Autenticado* | `{tripType?}` (default `ROUND_TRIP`) | `201 EntryResponse` | `400 LIST_CLOSED`, `404` |
| DELETE | `/api/lists/{id}/entries` | Autenticado* | — | `{success:true}` | `400 LIST_CLOSED`, `404` (sem inscrição ativa) |
| GET | `/api/lists/{id}/entries` | Autenticado | — | `EntryResponse[]` | `404` |
| GET | `/api/reports` | ADMIN | `?page&size&sort` (default `size=20`, `generatedAt,desc`) | `Page<ReportSummaryResponse>` | — |
| GET | `/api/reports/{id}` | ADMIN | — | `ReportDetailResponse` (com `snapshotData`) | `404` |
| POST | `/api/notifications/broadcast` | ADMIN | `{title, body}` | `{success:true}` | `400 VALIDATION_ERROR` |
| POST | `/api/devices/token` | Autenticado | `{token, platform}` | `{success:true}` | `400 VALIDATION_ERROR` |
| DELETE | `/api/devices/token` | Autenticado | — | `{success:true}` | — |

`*` Ver observação de segurança em §2 — a regra atual libera qualquer papel autenticado, não só `STUDENT`.

**Códigos de erro em uso:** `EMAIL_ALREADY_EXISTS` (409) · `ROUTE_ALREADY_EXISTS` / `ROUTE_NAME_CONFLICT` (409) ·
`LIST_CLOSED` (400) · `VALIDATION_ERROR` (400) · `INTERNAL_SERVER_ERROR` (500) · `404`/`401` sem
`code` estruturado adicional além de `{code: null?...}` — na prática `NotFoundException`/`UnauthorizedException`
usam a própria mensagem como `error`, sem um `code` fixo por tipo (checar `AppException.getCode()`
se precisar depender disso programaticamente).

---

## 7. Gaps — contrato proposto (não implementados)

### Gap 2 — Notificação de saída direcionada (motorista)

- **Precisa porque:** o Flutter (`DriverHomeScreen` + `driver_service.dart`) já está construído
  pra chamar esse endpoint — sem ele, o fluxo do motorista não pode ser testado ponta a ponta.
- **Contrato proposto** (já definido pelo Flutter, não é aberto):
  ```
  POST /api/lists/{id}/notifications/departure   · DRIVER, ADMIN

  Request (body opcional):
  { "title"?: string, "body"?: string }

  Response 200:
  { "data": { "success": true, "notified": <int> } }
  ```
  - Busca `list_entries` ativos da `daily_list_id={id}`, resolve `device_tokens`, envia FCM em
    loop (reaproveitar `SendToUserUseCase`, já usado por `ListUseCaseImpl.notifyEnrollment`).
  - Funciona independente do `status` da lista (`OPEN` ou `CLOSED`) — o embarque físico
    acontece depois do fechamento das 16h.
  - Sem inscritos ativos → sucesso com `notified: 0` (não é erro).
- **Quem implementa / quando:** a definir — fora do escopo desta spec (só documentação).

### Gap 3 — Broadcast automático de "lista aberta"

- **Precisa porque:** o app espera notificação #1 ("lista aberta") descrita em
  `smartboarding_app/docs/spec.md` §3.3, mas ela nunca dispara hoje.
- **Contrato proposto:** dentro de `SchedulerUseCaseImpl.open()`, adicionar chamada a
  `SendBroadcastUseCase` no mesmo padrão que `close()` já faz — ex.: "A lista de embarque de
  hoje já está disponível! Inscreva-se até as 16h." Só disparar se pelo menos uma lista foi
  criada (evitar broadcast vazio em dia sem rota ativa).
- **Quem implementa / quando:** a definir — fora do escopo desta spec.

### Gap 4 — Perfil estendido no cadastro de usuário

- **Precisa porque:** `users` já tem as colunas (`course`, `institution`, `phone`, `address`,
  `birth_date`, `expiry_date`) e `UserResponse` já as retorna, mas `RegisterRequest`/
  `POST /api/auth/register` não as aceita — o dado nunca é escrito, só fica `NULL`. O Flutter
  (`UserManagementScreen`/`UserModel`) também não coleta esses campos hoje — a menção em versões
  anteriores do `spec.md` do Flutter (§5.3) descrevia um formulário mais completo que nunca foi
  implementado nos dois lados.
- **Contrato proposto:** estender `RegisterRequest` com os campos opcionais correspondentes;
  `AuthUseCaseImpl.execute` já teria como persistí-los via `User.builder()`.
- **Quem implementa / quando:** a definir — não bloqueia nenhum fluxo atual (campos não
  aparecem em nenhuma tela hoje). Baixa prioridade.

---

## 8. Estratégia de Testes

- **Estado atual:** cobertura **praticamente zero**. Só existe `SmartboardingApiApplicationTests`
  — smoke test de contexto (`@SpringBootTest`, valida que o Spring sobe e as migrations aplicam
  num banco vazio). Não há teste de use case, controller, ou regra de negócio isolada.
- **Não testado hoje, e por quê isso é risco:** RN3/RN4 (janela de OPEN/CLOSED, reativação sem
  409), RN9/RN10 (conflitos de nome/e-mail), o scheduler inteiro (RN1/RN2) — tudo depende hoje
  de teste manual via `curl`/Postman antes de cada entrega. Ver §9.
- **Recomendado (fora do escopo desta spec, registrado como direção):** unit tests por
  `*UseCaseImpl` com repositórios mockados (Mockito), cobrindo os cenários de RN3/RN4/RN9/RN10;
  `@WebMvcTest` por controller pra contrato HTTP; um `@SpringBootTest` de integração pro
  ciclo completo do scheduler (`open()`→`close()`) com Testcontainers ou o Postgres do compose.
- **CI (`smartboarding-api` job):** roda `./mvnw test` contra Postgres 16 em service container
  (`5433:5432`) — hoje só executa o smoke test, então o gate de CI não pega regressão de regra
  de negócio.

---

## 9. Riscos e Dependências

| Risco/Dependência | Impacto | Mitigação |
|---|---|---|
| Cobertura de teste quase zero (§8) | Regressão de regra de negócio só aparece em teste manual ou em produção | Priorizar unit tests dos `*UseCaseImpl` antes de mexer em RN3/RN4/RN9/RN10 |
| Gaps 2/3 não implementados | Fluxo do motorista (já construído no Flutter) não pode ser testado ponta a ponta; notificação de "lista aberta" nunca dispara | Tratar como próxima demanda de implementação — contrato já está fechado (§7), não precisa de novo brainstorming |
| `/api/lists/{id}/entries` sem restrição de papel (§2) | Comportamento não documentado — pode ser intencional (DRIVER/ADMIN também embarcam) ou lacuna de segurança | Decidir explicitamente (issue) se deve virar `hasRole('STUDENT')` ou ficar como está |
| Gap 4 (perfil estendido) sem uso em nenhuma tela | Baixo — dado morto no schema, não trava fluxo nenhum | Nenhuma ação necessária até alguém precisar do campo |

---

## 10. O que NÃO fazer

- **Não usar a convenção de pacotes flat** (`Models/`, `Controllers/`, `Services/` capitalizados)
  — o código já migrou pra hexagonal (`domain/application/infrastructure`, §4.1). Documentação
  antiga que ainda citar isso está desatualizada; corrija no mesmo PR se encontrar.
  Motorista não deve ter acesso a gestão de rotas/usuários/relatórios — só o endpoint do Gap 2
  quando existir.
- Não editar `V1__initial_schema.sql`/`V2__seed_data.sql` — são migrations já aplicadas.
  Mudança de schema é `V3__...` nova.
- Não assumir que `POST /api/lists/{id}/entries` retorna 409 pra reinscrição — RN4 é reativação
  idempotente, não conflito.
- Não implementar os Gaps 2/3/4 como parte desta spec — ficaram documentados de propósito, pra
  uma demanda de implementação separada (decisão registrada em §0).
