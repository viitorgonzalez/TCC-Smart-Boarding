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
`notification`, `registration`.

### 3.2 Persistência

- PostgreSQL 16, Flyway. Migrations em `V1__initial_schema.sql` + `V2__seed_data.sql` +
  incrementais a partir de `V3`. Nunca editar uma migration já aplicada — mudança de schema é
  sempre uma migration nova.
- Tabelas: `users`, `routes`, `institutions`, `vehicles`, `stops`, `daily_lists`, `list_entries`
  (com `trip_type`), `reports` (com `proposed_vehicles`), `device_tokens`, `notifications`,
  `registration_requests`, `refresh_tokens`, `password_reset_tokens`. Todas com PK `UUID`.

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
- **Fechamento**: por rota, não global — cada rota tem seu próprio `closeTime` (default 16:00,
  editável pelo admin). O agendamento de fechamento é dinâmico (`TaskScheduler`/`ScheduledFuture`
  por rota), criado quando a lista do dia abre e recriado sempre que o admin edita o `closeTime`.
  No restart do servidor, os agendamentos são reconstruídos a partir das `DailyList` `OPEN` do
  dia (se o horário já passou no momento do restart, o fechamento roda imediatamente).
- `openTime` é sempre 00:00, fixo — não é um campo editável (só o fechamento varia entre rotas).

---

## 4. Regras de Negócio

### 4.1 Cadastro — convite e aprovação

- **RN13** — Aluno se cadastra por convite, não por autocadastro livre. `ADMIN` gera o convite
  (`POST /api/registration/invite`, só e-mail) — sistema cria um pedido de cadastro com token
  único e envia e-mail (via Resend) com um **Android App Link / iOS Universal Link**
  (`https://<domínio>/register/{token}`, não um esquema customizado). Com o app instalado, o
  link abre direto na tela de cadastro; sem o app, cai numa página web mínima do próprio backend
  pedindo pra instalar o app.
  - Token de convite válido por 7 dias, renovável pelo admin reenviando o convite.
  - Aluno preenche os dados (incluindo a instituição, escolhida entre as cadastradas) e submete
    — isso não cria a conta ainda, só marca o pedido como enviado, aguardando revisão.
  - `POST /api/auth/register` existe só pra `ADMIN` criar outro `ADMIN` diretamente, sem convite
    — não aceita `role=STUDENT` nem instituição.
- **RN14** — `ADMIN` lista os pedidos pendentes (`GET /api/registration/pending`) e aprova (cria
  a conta de fato) ou nega. Negar não invalida o token: enquanto ele não expirou, o aluno pode
  reenviar os dados e gerar uma nova avaliação.

### 4.2 Instituições e rotas

- **RN9** — Nome de rota é único entre rotas ativas. Deletar rota é soft-delete
  (`isActive=false`).
- **RN15** — `Institution` (nome, endereço, latitude/longitude) é cadastrada pelo `ADMIN` e
  vinculada a **exatamente uma** rota ativa por vez — vincular a uma instituição já vinculada a
  outra rota ativa retorna conflito. A rota de um aluno é sempre **derivada** da instituição
  escolhida no cadastro — o aluno nunca escolhe rota diretamente. Desativar uma rota desvincula
  automaticamente todas as instituições ligadas a ela, que ficam livres pra serem vinculadas a
  outra rota depois.
- **RN18** — `Route.closeTime` é editável pelo `ADMIN` (ver §3.5).
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
- **RN3** — Entrar/sair de uma lista só é permitido com `status=OPEN` — fora disso, erro
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

### 4.7 Trajeto

- **RN23** — Ações de trajeto (iniciar, checkpoint num ponto principal, finalizar) são
  exclusivas do `ADMIN` — não existe um papel de motorista separado. Checkpoint só é aceito em
  pontos marcados como principais (rodoviária + instituições da rota) — paradas comuns não geram
  checkpoint, só aparecem no mapa. Cada ação de trajeto dispara notificação FCM aos inscritos
  ativos da lista do dia, independente do `status` da lista (funciona mesmo com a lista já
  fechada — o embarque físico acontece depois do fechamento).

### 4.8 Sessão e segurança

- **RN10** — E-mail de usuário é único. Senha mínima de 6 caracteres.
- **RN21** — Sessão longa: ver mecanismo em §3.3. Refresh token só é emitido quando o login pede
  `rememberMe: true`.
- **RN22** — Recuperação de senha: `POST /api/auth/forgot-password` sempre responde
  `{success:true}`, mesmo se o e-mail não existir (não revela quais e-mails são cadastrados).
  `POST /api/auth/reset-password` troca a senha e invalida o token usado.

---

## 5. Entidades

| Entidade | Contexto | Campos principais |
|---|---|---|
| `User` | `user` | `id`, `email`, `password` (hash), `role` (`ADMIN`\|`STUDENT`), `fullName`, `course?`, `institution?`, `phone?`, `address?`, `birthDate?`, `expiryDate?` |
| `RefreshToken` | `user` | `id`, `userId`, `tokenHash`, `expiresAt` |
| `PasswordResetToken` | `user` | `id`, `userId`, `tokenHash`, `expiresAt` |
| `RegistrationRequest` | `registration` | `id`, `email`, `token`, `status` (`PENDING`\|`SUBMITTED`\|`APPROVED`\|`REJECTED`), `expiresAt`, dados submetidos (mesmos campos opcionais de `User` + `institutionId`) |
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
| POST | `/api/auth/reset-password` | Público | `{token, newPassword}` | `{success:true}` | `400` token inválido/expirado |
| POST | `/api/registration/invite` | ADMIN | `{email}` | `{id, token, expiresAt}` | — |
| GET | `/api/registration/invite/{token}` | Público | — | dados do convite | `404` |
| POST | `/api/registration/{token}/submit` | Público | `{fullName, password, institutionId, course?, phone?, address?, birthDate?}` | `{status: "SUBMITTED"}` | `400`, `404` |
| GET | `/api/registration/pending` | ADMIN | — | `RegistrationRequest[]` | — |
| POST | `/api/registration/{id}/approve` | ADMIN | — | `UserResponse` | `404` |
| POST | `/api/registration/{id}/reject` | ADMIN | — | `{success:true}` | `404` |
| GET | `/api/users` / `/api/users/{id}` | ADMIN | — | `UserResponse[]` / `UserResponse` | `404` |
| POST | `/api/routes` | ADMIN | `{name, description?}` | `RouteResponse` | `409` nome duplicado |
| GET | `/api/routes` | Público | — | `RouteResponse[]` (só ativas) | — |
| GET | `/api/routes/{id}` | Público | — | `RouteResponse` | `404` |
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
