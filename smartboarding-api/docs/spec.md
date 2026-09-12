# SmartBoarding API — Especificação

> Escopo: backend (`smartboarding-api/`). Descreve o sistema como ele **é** — contrato,
> arquitetura e regras de negócio no estado atual. Histórico de decisões e discussões de
> mudança vivem em `personal-harness/docs/work/`, não aqui.

---

## 1. Visão Geral

### Problema

O controle de embarque no ônibus universitário (Unifor + instituições parceiras) era feito
manualmente por grupo de WhatsApp: alunos escreviam o próprio nome numa lista, o grupo "fechava"
por mensagem humana, o tamanho do veículo era decidido contando nomes, e não havia aviso
automático de saída do ônibus. Sujeito a erro (duplicatas, fechamento atrasado) e não escalável.

### Objetivo do backend

- Persistir e servir listas diárias de embarque com abertura/fechamento automáticos por horário.
- Contar inscritos em tempo real, sem digitação manual.
- Resolver a rota de cada aluno automaticamente a partir da instituição vinculada.
- Gerenciar o fluxo de cadastro por convite, com aprovação do admin.
- Propor o veículo adequado no fechamento da lista, a partir da capacidade cadastrada.
- Disparar notificações push (FCM) nos momentos certos, e dar ao admin os endpoints de ação
  manual (trajeto, notificação livre).
- Expor um contrato estável o suficiente pro app Flutter consumir sem acoplamento a detalhes de
  persistência.

### Fora de escopo

- Rastreamento em tempo real (GPS) do ônibus — o mapa mostra pontos fixos, não a posição ao vivo.
- Pagamento/cobrança.
- Múltiplas rotas ativas atendendo a mesma instituição simultaneamente — cada instituição
  pertence a uma única rota ativa por vez.

---

## 2. Papéis e Permissões

Fonte de verdade: `SecurityConfig.java` (`infrastructure/config/`).

| Papel | Pode | Não pode |
|---|---|---|
| **Público** (sem token) | Login, consultar rotas, consultar/submeter convite de cadastro, recuperação de senha | Tudo o resto |
| **`STUDENT`** | Ver a lista do dia da própria rota (derivada da instituição), entrar/sair da própria inscrição, ver detalhe de rota (com mapa/paradas), registrar/remover o próprio device token, ver notificações (histórico), ver relatórios dos últimos 7 dias | Gerenciar rotas/instituições/veículos, aprovar cadastros, enviar notificações, ver relatórios além de 7 dias, ações de trajeto |
| **`ADMIN`** | Tudo: CRUD de rotas/instituições/veículos/paradas, aprovar/negar cadastros pendentes, gerar convite, criar outro ADMIN, listar usuários, ver relatórios completos, enviar notificações (com imagem), ações de trajeto (iniciar/checkpoint/finalizar) | — |

`/api/lists/{id}/entries` (entrar/sair da lista) libera qualquer papel autenticado, não só
`STUDENT` — comportamento intencional (admin também pode embarcar).

---

## 3. Arquitetura

### 3.1 Estrutura de pacotes (hexagonal / ports & adapters)

```
com.smartboarding.smartboarding_api/
├── domain/<contexto>/            # regra de negócio pura
│   ├── entity/                   # entidades do contexto
│   └── port/
│       ├── in/                   # *UseCase (interface) — o que o domínio oferece
│       └── out/                  # *RepositoryPort/porta de infra (interface)
├── application/<contexto>/       # *UseCaseImpl — implementação dos casos de uso
├── infrastructure/
│   ├── web/<contexto>/           # *Controller + dto/ (Request/Response)
│   │   └── common/               # GlobalExceptionHandler
│   ├── email/                    # ResendEmailAdapter
│   ├── storage/                  # R2StorageAdapter
│   ├── fcm/                      # FcmAdapter
│   └── config/                   # SecurityConfig, FirebaseConfig, ...
└── shared/
    ├── exception/                 # AppException, NotFoundException, ConflictException,
    │                               # UnauthorizedException, BadRequestException
    └── web/                       # ApiResponse<T>
```

Contextos (`<contexto>`): `user`, `route`, `institution`, `vehicle`, `stop`, `list`, `report`,
`notification`, `membership`.

### 3.2 Persistência

- PostgreSQL 16, Flyway. Migrations em `V1__initial_schema.sql` + `V2__seed_data.sql` +
  incrementais a partir de `V3`. Nunca editar uma migration já aplicada — mudança de schema é
  sempre uma migration nova.
- Tabelas: `users`, `routes`, `institutions`, `vehicles`, `stops`, `daily_lists`, `list_entries`
  (com `trip_type`), `reports` (com `proposed_vehicles`), `device_tokens`, `notifications`,
  `route_invite_codes`, `route_members`, `user_institutions`, `password_reset_requests`.
  Todas com PK `UUID`.

### 3.3 Autenticação e sessão

- JWT via `spring-security-oauth2-resource-server`, algoritmo HS256, expiração de 1h, issuer
  `smartboarding-api`. Claim `scope` carrega o papel do usuário, prefixado `ROLE_` na conversão
  pra `hasRole(...)`.
- Senha: BCrypt.
- Sessão longa: login com `rememberMe: true` também emite um refresh token (opaco, armazenado
  hasheado), válido por 7 dias. `POST /api/auth/refresh` troca um refresh token válido por um
  novo JWT de 1h. Sem `rememberMe`, nenhum refresh token é emitido.
- Sessão stateless, CSRF desabilitado (API pura, sem cookie).

### 3.4 Envelope de resposta

- Sucesso: `{ "data": <payload> }`. Operação sem payload de retorno: `{ "data": { "success": true } }`.
- Erro: `{ "code": "<CODIGO>", "error": "<mensagem>" }`.

### 3.5 Scheduler

- `@EnableScheduling`, em `SchedulerUseCaseImpl` (`application/list/`).
- **Abertura**: às 00:00 (seg-sex), cron único e global — para cada `Route` ativa sem
  `DailyList` do dia, cria uma com `status=OPEN`. Se pelo menos uma lista foi criada, dispara
  broadcast FCM avisando que a lista do dia está disponível.
- **Fechamento**: por rota, não global — cada rota tem seu próprio `closeTime` (`routes.close_time`,
  default 16:00, editável pelo admin via `PATCH /api/routes/{id}`).
  **Implementado como varredura periódica** (`@Scheduled` a cada 5 min) que fecha toda `DailyList`
  `OPEN` de hoje cujo `closeTime` já passou — não como `TaskScheduler`/`ScheduledFuture` por rota.
  A varredura dá de graça o requisito de recuperar fechamento atrasado após restart, sem precisar
  reconstruir agendamentos, ao custo de fechar com atraso de até 5 min.
- **A inscrição não depende do agendador.** `add`/`remove` validam contra o relógio (data de hoje
  + `closeTime` da rota), não contra a flag `status`. Sem isso, uma janela em que o agendador não
  rodou (API fora do ar no horário, restart, deploy) deixaria a lista `OPEN` e aceitando inscrição
  fora de hora — que foi exatamente o bug observado em 28/08/2026.
- `openTime` é sempre 00:00, fixo — não é um campo editável (só o fechamento varia entre rotas).

---

## 4. Regras de Negócio

### 4.1 Cadastro — autocadastro e código de rota

- **RN13** — Aluno se cadastra sozinho (`POST /api/auth/signup`, só nome, e-mail e senha) e já
  recebe a sessão. A conta nasce **sem rota**: existir no sistema e pertencer a uma rota são
  coisas separadas.
  - `POST /api/auth/register` existe só pra `ADMIN` criar outro `ADMIN` — não aceita
    `role=STUDENT`.
  - `POST /api/auth/google` entra pelo Google; quem entrou assim pode definir uma senha local
    depois (`POST /api/me/password`) e passa a ter os dois caminhos.
- **RN14** — O acesso à rota vem de um **código** que o `ADMIN` gera
  (`POST /api/routes/{routeId}/invite-codes`) e distribui. O aluno entra com ele
  (`POST /api/me/routes`), e pode pertencer a mais de uma rota.
  - Código tem validade (`ROUTE_INVITE_VALIDITY_DAYS`, default 30 dias) e pode ser revogado.
  - Entrar exige perfil com instituição definida — sem isso a API recusa com
    `PROFILE_INCOMPLETE`.

### 4.2 Instituições e rotas

- **RN9** — Nome de rota é único entre rotas ativas. Deletar rota é soft-delete
  (`isActive=false`).
- **RN15** — `Institution` (nome, endereço, latitude/longitude) é cadastrada pelo `ADMIN` e
  vinculada a **exatamente uma** rota ativa por vez — vincular a uma instituição já vinculada a
  outra rota ativa retorna conflito. A rota de um aluno é sempre **derivada** da instituição
  escolhida no cadastro — o aluno nunca escolhe rota diretamente. Desativar uma rota desvincula
  automaticamente todas as instituições ligadas a ela, que ficam livres pra serem vinculadas a
  outra rota depois.
- **RN18** — `Route.openTime` e `Route.closeTime` são editáveis pelo `ADMIN`, mas só pelo endpoint
  próprio `PATCH /api/routes/{id}/schedule`, que **exige motivo** e avisa a rota. Uma varredura a
  cada minuto abre e fecha a lista do dia de cada rota nesses horários — segunda a sexta — e cada
  abertura/fechamento automático grava um aviso na caixa da rota. Uma rota tem **no máximo uma
  lista por data** (`409 LIST_ALREADY_EXISTS`).
- **RN24** — Abrir ou fechar a lista fora do horário configurado é permitido ao `ADMIN`, mas exige
  um motivo (`400 REASON_REQUIRED` sem ele). O motivo vira o corpo de uma notificação enviada a
  todos os alunos da rota — não é opcional: quem depende do transporte precisa saber da mudança.
  A decisão manual **vence a varredura** no mesmo dia (`daily_lists.manual_override`): sem isso,
  reabrir depois do `closeTime` durava até o próximo tique. Lista de dia passado fecha mesmo com
  override — o dia do admin acabou.
- **RN26** — O `ADMIN` pode incluir um aluno na lista **mesmo fechada**
  (`POST /api/lists/{id}/entries/admin`), porque às vezes ele realmente vai embarcar. A inclusão
  pode gerar uma **advertência** ao aluno — colocar o nome no prazo é responsabilidade dele —, mas
  emitir é **escolha do admin** (`issueWarning`): nem todo atraso é falta do aluno (ônibus
  adiantado, problema no app, decisão da coordenação). O aluno vê só as próprias
  (`GET /api/warnings/me`); o admin vê todas e pode remover as aplicadas por engano.
- **RN19** — Editar qualquer regra de uma rota (horário de fechamento, instituições vinculadas,
  paradas, veículos) dispara uma notificação automática pros usuários vinculados àquela rota —
  texto gerado pelo sistema, não pelo admin.

### 4.3 Veículos e proposta de frota

- **RN16** — `Vehicle` (tipo, capacidade) é cadastrado pelo `ADMIN`, vinculado a uma rota — uma
  rota pode ter vários veículos disponíveis. No fechamento da lista, o relatório calcula e
  persiste o(s) veículo(s) proposto(s), por um algoritmo guloso:
  1. Ordena os veículos da rota por capacidade decrescente.
  2. Aloca o de maior capacidade primeiro, até o limite dele.
  3. Se sobrar gente, busca entre os veículos restantes o de **menor** capacidade que ainda cubra
     o resto, e aloca também.
  4. Repete até cobrir todos os inscritos ou esgotar a frota da rota — nesse caso, o relatório
     marca capacidade insuficiente.
  - É uma heurística gulosa, não a combinação matematicamente ótima — suficiente pro porte de
    frota por rota.

### 4.4 Listas diárias

- **RN1** — Lista diária abre automaticamente às 00:00 (seg-sex) pra cada rota ativa.
  Idempotente: se já existe lista pra (rota, data), não recria.
- **RN2** — Lista fecha automaticamente no `closeTime` da rota (ver §3.5): `status=CLOSED`,
  `closedAt=now()`, gera relatório (snapshot dos inscritos ativos + veículo proposto) e dispara
  notificação FCM aos inscritos.
- **RN3** — Entrar/sair de uma lista só é permitido com `status=OPEN`, **na lista de hoje e antes
  do `closeTime` da rota** (as três condições são checadas no use case, não só a flag) — fora disso, erro
  `LIST_CLOSED`.
- **RN4** — Uma inscrição por (usuário, lista) — reentrar numa lista onde o usuário já tem
  inscrição **reativa** o registro existente (idempotente, não gera conflito) e atualiza o
  `tripType` se vier diferente.
- **RN5** — Sair da lista é soft-delete (`isActive=false`) — nunca exclusão física. O aluno pode
  reentrar na mesma lista, no mesmo dia, enquanto ela estiver `OPEN`.
- **RN6** — Cada inscrição tem um `tripType`: `ROUND_TRIP` (padrão), `TO_CAMPUS` ou
  `FROM_CAMPUS`.
- **RN7** — Ao entrar na lista (criação ou reativação), dispara notificação FCM individual de
  confirmação — best-effort, falha no envio não propaga erro pro cliente.
- **RN12** — `users.expiryDate` é a validade da carteirinha física de transporte. Quando
  expirada, a conta é bloqueada: login retorna erro `ACCOUNT_EXPIRED` em vez de emitir o JWT, e
  entrar na lista revalida `expiryDate` de novo (necessário porque um JWT emitido antes da
  expiração continua válido por até 1h). `expiryDate = null` (comum em `ADMIN`) nunca expira.

### 4.5 Relatórios

- **RN8** — Relatório é gerado automaticamente no fechamento da lista, é imutável (sem endpoint
  de edição) e traz o snapshot dos inscritos ativos + o(s) veículo(s) proposto(s) (§4.3).
- **RN17** — `ADMIN` vê o histórico completo, paginado. `STUDENT` só vê relatórios dos últimos 7
  dias — o filtro é aplicado no backend, não é opcional via query param.

### 4.6 Notificações

- **RN20** — Toda notificação enviada (automática ou manual) é persistida — histórico
  consultável por `ADMIN` (todas) e `STUDENT` (as gerais + as da própria rota). Envio manual é
  exclusivo do `ADMIN`, com escopo geral ou restrito a uma rota, e suporta imagem anexada. Upload
  de imagem é feito via proxy pelo backend: o admin manda a imagem, o backend sobe pro Cloudflare
  R2 (client S3-compatible) e guarda a URL pública. O payload do push FCM em si carrega só título
  e corpo — a imagem não vai no push (evitaria depender de processamento nativo específico por
  plataforma no cliente); ela aparece quando o destinatário abre o histórico no app.

- **RN25** — `ScheduledNotification` é um aviso recorrente de uma rota, cadastrado pelo `ADMIN`
  com frequência (`DAILY`/`WEEKDAYS`/`WEEKLY`), horário de envio e validade opcional em horas. A
  mesma varredura de 5 min despacha os que estão vencidos, no máximo **um envio por dia** por
  aviso (`lastSentAt`). Pode ser pausado sem perder o cadastro.

### 4.7 Trajeto

- **RN23** — Ações de trajeto (iniciar, checkpoint num ponto principal, finalizar) são
  exclusivas do `ADMIN` — não existe um papel de motorista separado. Um trajeto por lista do dia:
  o estado mora em `daily_lists.trip_started_at`/`trip_finished_at` e cada chegada vira uma linha
  em `trip_checkpoints`, com `UNIQUE (lista, parada)` — o checkpoint é **idempotente**, tocar duas
  vezes não gera segunda chegada nem segundo aviso. Ponto principal é `stops.is_main_point`. Cada
  ação **persiste** o aviso além de disparar o push: push não deixa registro, e sem isso o aluno
  não veria nada. Checkpoint só é aceito em
  pontos marcados como principais (rodoviária + instituições da rota) — paradas comuns não geram
  checkpoint, só aparecem no mapa. Cada ação de trajeto dispara notificação FCM aos inscritos
  ativos da lista do dia, independente do `status` da lista (funciona mesmo com a lista já
  fechada — o embarque físico acontece depois do fechamento).

### 4.8 Sessão e segurança

- **RN10** — E-mail de usuário é único. Senha mínima de 6 caracteres.
- **RN21** — Sessão longa: ver mecanismo em §3.3. Refresh token só é emitido quando o login pede
  `rememberMe: true`.
- **RN22** — Recuperação de senha por **código de 6 dígitos** enviado por e-mail (não link: App
  Link exige domínio publicado e verificado, pendência de deploy — mesmo motivo do convite).
  `POST /api/auth/forgot-password` sempre responde `{success:true}`, mesmo se o e-mail não existir
  (não revela quais e-mails são cadastrados). `POST /api/auth/reset-password {email, code,
  newPassword}` troca a senha e queima o código. O código é hasheado no banco, vale por
  `app.password-reset.code-ttl-minutes`, é de uso único, tem limite de tentativas e emitir um novo
  invalida os anteriores.

---

## 5. Entidades

| Entidade | Contexto | Campos principais |
|---|---|---|
| `User` | `user` | `id`, `email`, `password` (hash), `role` (`ADMIN`\|`STUDENT`), `fullName`, `course?`, `institution?`, `phone?`, `address?`, `birthDate?`, `expiryDate?` |
| `RefreshToken` | `user` | `id`, `userId`, `tokenHash`, `expiresAt` |
| `PasswordResetToken` | `user` | `id`, `userId`, `tokenHash`, `expiresAt` |
| `RouteInviteCode` | `membership` | `id`, `routeId`, `code`, `expiresAt`, `revokedAt?`, `createdBy` |
| `RouteMember` | `membership` | `id`, `userId`, `routeId`, `joinedAt` — único por par |
| `UserInstitution` | `membership` | `id`, `userId`, `institutionId` — único por par |
| `Route` | `route` | `id`, `name`, `description?`, `isActive`, `closeTime` |
| `Institution` | `institution` | `id`, `name`, `address`, `latitude`, `longitude`, `routeId?` |
| `Vehicle` | `vehicle` | `id`, `routeId`, `type`, `capacity` |
| `Stop` | `stop` | `id`, `routeId`, `name`, `latitude`, `longitude`, `isMainPoint`, `order` |
| `DailyList` | `list` | `id`, `routeId`, `date`, `status` (`OPEN`\|`CLOSED`), `closedAt?`, `startedAt?`, `finishedAt?` |
| `ListEntry` | `list` | `id`, `userId`, `dailyListId`, `isActive`, `tripType` |
| `Report` | `report` | `id`, `dailyListId`, `generatedAt`, `totalEntries`, `snapshotData`, `proposedVehicles` |
| `Notification` | `notification` | `id`, `title`, `body`, `imageUrl?`, `scope` (`BROADCAST`\|`ROUTE`), `routeId?`, `sentBy`, `sentAt` |
| `DeviceToken` | `notification` | `id`, `userId`, `token`, `platform` |

---

## 6. Contratos de API

> Fonte: código (`infrastructure/web/**/*Controller.java` + `dto/`). Divergiu? O código vence —
> corrija esta tabela no mesmo PR.

| Método | Path | Acesso | Request | Response | Erros |
|---|---|---|---|---|---|
| POST | `/api/auth/login` | Público | `{email, password, rememberMe?}` | `{token, fullName, role, refreshToken?}` | `401` credenciais inválidas, `401 ACCOUNT_EXPIRED` |
| POST | `/api/auth/refresh` | Público (com refresh token) | `{refreshToken}` | `{token}` | `401` token inválido/expirado |
| POST | `/api/auth/register` | ADMIN | `{email, password≥6, fullName}` | `UserResponse` (role sempre ADMIN) | `409 EMAIL_ALREADY_EXISTS`, `400 VALIDATION_ERROR` |
| POST | `/api/auth/forgot-password` | Público | `{email}` | `{success:true}` (sempre) | — |
| POST | `/api/auth/reset-password` | Público | `{email, code, newPassword}` | `{success:true}` | `400` `INVALID_CODE` / `CODE_EXPIRED` / `TOO_MANY_ATTEMPTS` |
| POST | `/api/auth/signup` | Público | `{fullName, email, password}` | `{token, fullName, role, email}` | `400`, `409` |
| POST | `/api/auth/google` | Público | `{idToken}` | `{token, fullName, role, email}` | `401` |
| POST | `/api/routes/{routeId}/invite-codes` | ADMIN | `{expiresAt?}` | `{id, code, expiresAt}` | `404` |
| DELETE | `/api/routes/{routeId}/invite-codes/{codeId}` | ADMIN | — | `{success:true}` | `404` |
| GET | `/api/me/routes` | Autenticado | — | `RouteResponse[]` | — |
| POST | `/api/me/routes` | Autenticado | `{code}` | `RouteResponse` | `400` (`PROFILE_INCOMPLETE`), `404`, `410` |
| DELETE | `/api/me/routes/{routeId}` | Autenticado | — | `{success:true}` | `404` |
| GET | `/api/me` | Autenticado | — | `{id, fullName, email, role, hasPassword, hasGoogle}` | — |
| POST | `/api/me/password` | Autenticado | `{password}` | `{success:true}` | `400`, `409` |
| GET | `/api/users` / `/api/users/{id}` | ADMIN | — | `UserResponse[]` / `UserResponse` | `404` |
| POST | `/api/routes` | ADMIN | `{name, description?}` | `RouteResponse` | `409` nome duplicado |
| GET | `/api/routes` | Público | — | `RouteResponse[]` (só ativas) | — |
| GET | `/api/routes/{id}` | Público | — | `RouteResponse` | `404` |
| GET | `/api/routes/{id}/stops` | Autenticado | — | `StopResponse[]` (ordenadas) | — |
| POST | `/api/routes/{id}/stops` | ADMIN | `{name, latitude?, longitude?, sequence?}` | `StopResponse` | `400` |
| DELETE | `/api/routes/{id}/stops/{stopId}` | ADMIN | — | `success` | — |
| GET | `/api/routes/{id}/vehicles` | ADMIN | — | `VehicleResponse[]` | — |
| POST | `/api/routes/{id}/vehicles` | ADMIN | `{label, capacity}` | `VehicleResponse` | `400` |
| DELETE | `/api/routes/{id}/vehicles/{vehicleId}` | ADMIN | — | `success` | — |
| PATCH | `/api/institutions/{id}/route` | ADMIN | `{routeId?}` | `InstitutionResponse` | `404`, `409 INSTITUTION_ALREADY_LINKED` |
| GET | `/api/admin/stats` | ADMIN | — | `{activeStudents, routesInUse, occupancyPercent}` | — |
| PATCH | `/api/routes/{id}` | ADMIN | `{name?, description?, closeTime?}` | `RouteResponse` | `404`, `409` nome duplicado |
| DELETE | `/api/routes/{id}` | ADMIN | — | `{success:true}` (soft-delete) | `404` |
| CRUD | `/api/institutions` | ADMIN (write) / Autenticado (read) | `{name, address, latitude, longitude, routeId?}` | `Institution[]` / `Institution` | `409 INSTITUTION_ALREADY_LINKED` |
| CRUD | `/api/routes/{id}/vehicles` | ADMIN | `{type, capacity}` | `Vehicle[]` / `Vehicle` | `404` |
| CRUD | `/api/routes/{id}/stops` | ADMIN (write) / Autenticado (read) | `{name, latitude, longitude, isMainPoint, order}` | `Stop[]` / `Stop` | `404` |
| GET | `/api/lists/today` | Autenticado | — | `ListResponse[]` (filtrado pela rota do usuário, se `STUDENT`) | — |
| GET | `/api/lists/{id}` | Autenticado | — | `ListResponse` | `404` |
| POST | `/api/lists/{id}/entries` | Autenticado | `{tripType?}` (default `ROUND_TRIP`) | `201 EntryResponse` | `400 LIST_CLOSED`, `404`, `403 ACCOUNT_EXPIRED` |
| DELETE | `/api/lists/{id}/entries` | Autenticado | — | `{success:true}` | `400 LIST_CLOSED`, `404` |
| GET | `/api/lists/{id}/entries` | Autenticado | — | `EntryResponse[]` | `404` |
| GET | `/api/reports` | Autenticado | `?page&size` (filtro de 7 dias server-side se `STUDENT`) | `Page<ReportSummaryResponse>` | — |
| GET | `/api/reports/{id}` | ADMIN | — | `ReportDetailResponse` | `404` |
| POST | `/api/notifications` | ADMIN | `{title, body, imageUrl?, scope, routeId?}` | `Notification` | `400 VALIDATION_ERROR` |
| POST | `/api/notifications/upload-image` | ADMIN | multipart | `{imageUrl}` | — |
| GET | `/api/notifications` | Autenticado | `?page&size` | `Page<Notification>` (filtrado por escopo/rota) | — |
| POST | `/api/trip/{listId}/start` | ADMIN | — | `{success:true}` | `404` |
| POST | `/api/trip/{listId}/checkpoint/{stopId}` | ADMIN | — | `{success:true}` | `404` se stop não é ponto principal |
| POST | `/api/trip/{listId}/finish` | ADMIN | — | `{success:true}` | `404` |
| POST | `/api/devices/token` | Autenticado | `{token, platform}` | `{success:true}` | `400 VALIDATION_ERROR` |
| DELETE | `/api/devices/token` | Autenticado | — | `{success:true}` | — |

**Códigos de erro em uso:** `EMAIL_ALREADY_EXISTS`, `ROUTE_ALREADY_EXISTS`/`ROUTE_NAME_CONFLICT`,
`INSTITUTION_ALREADY_LINKED`, `LIST_CLOSED`, `ACCOUNT_EXPIRED`, `VALIDATION_ERROR`,
`INTERNAL_SERVER_ERROR`.

---

## 7. Integrações Externas

- **Firebase Admin SDK** — push FCM. Credenciais via `FIREBASE_CREDENTIALS_PATH`; vazio desabilita
  o envio (a aplicação sobe do mesmo jeito, notificações só são logadas como puladas).
- **Resend** — e-mail de convite de cadastro e recuperação de senha. `RESEND_API_KEY` +
  `RESEND_FROM_EMAIL` (domínio verificado no Resend).
- **Cloudflare R2** (S3-compatible) — imagem de notificação, upload em proxy pelo backend.
  `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`,
  `R2_PUBLIC_BASE_URL`.
- **Google Maps Platform** (camada gratuita) — exibição de instituições/paradas no mapa do app;
  sem tracking em tempo real. Cota gratuita é um crédito mensal, não ilimitado — vigiar consumo
  se o número de rotas/instituições crescer.

---

## 8. Deploy

- Hospedado no Render (free tier). Anti-hibernação via workflow do GitHub Actions
  (`schedule: cron`, ~10min) fazendo `curl` num endpoint de health check.
- Política: `main` é produção — nenhuma integração externa (Resend, R2, Firebase) é mergeada sem
  ser validada de ponta a ponta contra o serviço real, não só mockada localmente.

---

## 9. Estratégia de Testes

- Unit tests por `*UseCaseImpl` com repositórios mockados (Mockito). Integração via
  `@SpringBootTest` contra o Postgres do compose/CI.
- **Quality gate de cobertura** — `jacoco-maven-plugin`, mecanismo de ratchet: cada PR compara a
  cobertura atual com `.coverage-baseline`; regressão falha o build, ganho não refletido no
  arquivo também falha (força atualizar o número no mesmo PR). Meta declarada de longo prazo:
  80% — o gate em si só exige não regredir.
- **Quality gate de tamanho de arquivo** — nenhum arquivo `.java` de produção tocado num PR passa
  de 300 linhas (checado em CI, só nos arquivos do diff — não é sweep completo do repo). Tarefas
  pequenas miram bem abaixo disso (~60 linhas), por julgamento de quem planeja/implementa, não
  por regra mecânica.
- Sem comentários no código, exceto pra explicar a correção de um bug muito específico.

---

## 10. Riscos e Dependências

| Risco | Impacto | Mitigação |
|---|---|---|
| Cota gratuita do Google Maps Platform não é ilimitada | Uso real pode gerar custo se o número de rotas/instituições crescer | Validar consumo estimado; monitorar no console do Google Cloud |
| Render free tier tem limites além de hibernação (CPU/RAM baixos, sem SLA) | Pode não aguentar carga real fora do escopo do TCC | Aceito como risco conhecido; migrar de plano é decisão futura |
| Resend e Cloudflare R2 sem histórico de uso no projeto | Falha de configuração só aparece em produção se não testado de ponta a ponta | Validar contra os serviços reais antes de mergear (§8) |
| `/api/lists/{id}/entries` sem restrição de papel | Qualquer autenticado (não só `STUDENT`) entra/sai de lista — pode ser intencional (admin também embarca) ou lacuna de segurança | Decidir explicitamente se deve virar `hasRole('STUDENT')` — ponto em aberto, não bloqueia |

---

## 11. O que NÃO fazer

- Não usar convenção de pacotes flat (`Models/`, `Controllers/`, `Services/` capitalizados) — a
  arquitetura é hexagonal (§3.1).
- Não editar uma migration já aplicada — mudança de schema é sempre uma migration nova.
- Não assumir que `POST /api/lists/{id}/entries` retorna conflito pra reinscrição — é reativação
  idempotente (§4.4).
- Não recriar um papel de motorista separado — trajeto é ação do `ADMIN` (§4.7).
- Não deixar `POST /api/auth/register` aceitar `role=STUDENT` ou instituição — aluno nasce só
  pelo fluxo de convite (§4.1).
- Não deixar `STUDENT` acessar relatório fora da janela de 7 dias (§4.5).
- Não vincular uma instituição a mais de uma rota ativa (§4.2).
- Não passar de 300 linhas por arquivo `.java` tocado num PR (§9).
- Não mergear na `main` uma integração externa só testada localmente/mockada (§8).
- Não bloquear a notificação de trajeto por status de lista fechada (§4.7).

---

## 8. Estado de implementação (2026-08-28)

Registro do que saiu do papel nesta rodada, pra a spec não descrever intenção como se fosse
comportamento.

### Implementado

- **RN15 — rota derivada da instituição.** `institutions.route_id` e `users.institution_id`
  (a coluna de texto `users.institution` foi substituída pela referência). Uma rota atende
  **várias** instituições: em Formiga, IFMG e UNIFOR-MG dividem o mesmo transporte e a mesma
  lista. `GET /api/lists/today` filtra pela rota derivada quando o solicitante é `STUDENT`, e
  `POST /entries` recusa lista de outra rota (`400 ROUTE_NOT_ALLOWED`) — filtrar só na listagem
  deixaria a API aceitando um POST direto.
- **RN16 — veículo proposto.** Algoritmo guloso em `VehicleAllocator`, aplicado no fechamento e
  persistido em `reports.proposed_vehicles` / `reports.capacity_shortfall`. Capacidade **não** é
  teto de inscrição: é o que decide o transporte depois que o total de confirmados é conhecido.
- **RN18 — `openTime`/`closeTime` por rota**, editáveis, com varredura periódica de 5 min que
  abre e fecha a lista do dia.
- **RN24 — abrir/fechar manual com motivo obrigatório**, que vira notificação pra rota, e que a
  varredura respeita até o dia virar.
- **RN26 — inclusão tardia pelo admin** com advertência opcional (`warnings`).
- **RN25 — avisos recorrentes por rota** (`scheduled_notifications`), despachados pela varredura.
- Paradas (`stops`) com coordenadas, exibidas em mapa OpenStreetMap no app.

### Ainda não implementado

- Instituição sem rota vinculada deixa o aluno sem nenhuma lista visível. O comportamento é
  intencional (melhor que ver transporte alheio), mas não há aviso na tela explicando o motivo.
- Fuso: o servidor usa `app.timezone` (default `America/Sao_Paulo`); o app usa a hora do
  aparelho. Divergência entre os dois desalinha o countdown da tela com a decisão da API.
