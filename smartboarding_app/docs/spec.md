# SmartBoarding App (Flutter) — Design & Regras de Negócio

> Status: aprovado para implementação (fase de Flutter).
> Data: 2026-07-11
> Escopo desta fase: **app Flutter**. Mudanças de backend estão documentadas na seção 8 como dependências conhecidas, não implementadas ainda.

---

## 0. Registro de Decisões

Decisões tomadas durante o brainstorming deste design, com o motivo — para não precisar re-discutir depois:

| Decisão | Escolha | Motivo |
|---|---|---|
| Plataformas | Android + iOS | Uso real é mobile; projeto hoje só tem `windows/macos/linux` gerados por padrão — faltam `android/` e `ios/` |
| Papel do motorista | Novo role `DRIVER` (não reaproveitar ADMIN) | Motorista não deve ter acesso a gestão de rotas/usuários/relatórios — só precisa postar a notificação de saída |
| Alcance da notificação de saída | Só inscritos ativos da lista do dia (não broadcast) | Mais relevante — só quem vai embarcar precisa saber que o ônibus está saindo |
| Vínculo motorista↔rota | Sem vínculo fixo no banco por enquanto | Hoje existe uma rota principal só; motorista seleciona a lista na tela. Evita over-engineering (YAGNI) |
| Mecanismo da notificação de saída | Push direto por token (reaproveita `device_tokens` + `FcmPort` existente) | Mais simples que FCM Topics; sem gerenciamento de inscrição/desinscrição de tópico no client |
| Geração do client HTTP | ~~`openapi-generator` (generator `dart-dio`)~~ → **Revisado 2026-07-11: manter services manuais existentes** | Os services manuais em cima do Dio já funcionam e compilam. Migrar exigiria backend rodando + tooling extra e reescreveria código que já funciona (YAGNI). `openapi-generator` fica como opção futura, não bloqueante. |
| Cadastro de usuários | Só ADMIN cria contas (aluno, motorista, admin) — sem autocadastro | Mantém a regra que já existe no backend hoje |
| Cor principal do tema | Verde, com fundo branco (light) ou preto (dark) | Pedido explícito do usuário |
| Escopo desta fase | Só o Flutter; gaps de backend documentados mas não implementados agora | Definido pelo usuário — backend já cobre a maior parte do necessário |
| Prazo | Meta interna de ~1 mês (entrega oficial do TCC início de novembro/2026) | Dá margem de sobra, mas usada pra não superdimensionar o escopo inicial |
| Setup do Firebase (2026-07-11) | Código do app 100% estruturado agora; ativação real (projeto no Firebase Console + `flutterfire configure` + `firebase_options.dart`) fica para o usuário fazer depois | Criar projeto no Firebase Console é passo interativo com login Google que só o usuário faz. Estruturar o código não bloqueia o resto do front. |

---

## 1. Visão Geral

### Problema

O controle de embarque no ônibus universitário hoje é feito manualmente por um grupo de WhatsApp:
- Alunos escrevem o próprio nome numa lista copiada/colada dentro do grupo.
- O grupo "fecha" (para de aceitar novos nomes) às 16h — horário informal, controlado por mensagem humana.
- O ônibus sai às 17h30 da rodoviária.
- O tamanho do veículo do dia é decidido contando manualmente quantos nomes foram postados.
- Não existe aviso automático de quando o ônibus está de fato saindo.

Isso é sujeito a erro (nomes duplicados, lista desatualizada, fechamento atrasado/adiantado por esquecimento) e não escala.

### Objetivo do app

Substituir esse processo por um fluxo confiável:
1. Lista diária com abertura/fechamento **automáticos por horário** (já implementado no backend).
2. Contagem de inscritos em tempo real, sem digitação manual de nomes.
3. Notificações push nos momentos certos: lista aberta, lista fechada, ônibus saindo.

### Fora de escopo (por enquanto)

- Múltiplas rotas simultâneas ativas de verdade (o backend suporta, mas o uso real é uma rota principal).
- Autocadastro de usuários.
- Pagamento/cobrança.
- Rastreamento em tempo real (GPS) do ônibus.

---

## 2. Papéis e Permissões

| Papel | Quem é | Pode fazer |
|---|---|---|
| `STUDENT` | Aluno que usa o transporte | Ver lista(s) do dia, entrar/sair da lista dentro da janela permitida, registrar device token, receber notificações |
| `DRIVER` *(novo — gap de backend, seção 8)* | Motorista do ônibus | Ver lista(s) do dia, postar notificação de saída do ônibus para os inscritos ativos |
| `ADMIN` | Gestão do transporte | Tudo: gerenciar rotas, criar usuários (qualquer papel), ver relatórios históricos, enviar broadcast manual |

Sem autocadastro em nenhum papel — toda conta é criada por um ADMIN via `POST /api/auth/register`.

---

## 3. Regras de Negócio

### 3.1 Ciclo de vida da lista diária (já implementado no backend)

- **00:00** (seg-sex): sistema cria automaticamente uma `DailyList` com `status=OPEN` para cada rota ativa.
- **16:00** (seg-sex): sistema fecha todas as listas `OPEN` → `CLOSED`, gera `Report` com snapshot dos inscritos ativos.
- Se já existe lista para (rota, data), não recria — idempotente.
- **Entre 16:01 e 23:59 não existe lista `OPEN`** — o app deve impedir/esconder a ação de entrar na lista nesse período e mostrar mensagem explicativa.
- Entrar/sair da lista só é permitido com `status=OPEN`.

### 3.2 Inscrição na lista

- Um aluno tem no máximo **uma inscrição ativa** por (aluno, lista do dia) — `UNIQUE(user_id, daily_list_id)` no backend.
- Sair da lista é soft-delete (`is_active=false`) — o aluno pode voltar a entrar na mesma lista no mesmo dia enquanto ela estiver `OPEN`.
- Contagem de inscritos exibida no app = `COUNT WHERE is_active = true`.

### 3.3 Notificações — 3 tipos

| # | Notificação | Gatilho | Destinatários | Conteúdo esperado |
|---|---|---|---|---|
| 1 | Lista aberta | Automático, 00:00 | Todos (broadcast) | Avisa que a lista do dia está disponível e o horário limite (16h) |
| 2 | Lista fechada | Automático, 16:00 | Todos (broadcast) | Avisa que a lista fechou |
| 3 | Ônibus saindo da rodoviária | Manual — motorista posta pelo app | Só inscritos ativos da lista do dia | Aviso de embarque iminente |

Regra importante: a notificação #3 **não depende do status da lista** — pode (e deve) ser postada mesmo com a lista já `CLOSED`, já que o embarque físico acontece às 17h30, depois do fechamento das 16h.

### 3.4 Rotas e usuários (herdadas do backend, sem mudança)

- Nome de rota único entre rotas ativas — conflito retorna 409.
- Delete de rota é soft (`is_active=false`).
- E-mail de usuário único — 409 se já cadastrado.
- Senha: mínimo 6 caracteres.

---

## 4. Arquitetura Flutter

### 4.1 Estrutura de pastas

```
smartboarding-app/
├── packages/
│   └── smartboarding_api_client/     # gerado via openapi-generator (dart-dio) — não editar à mão
├── openapi/
│   └── openapi.json                  # snapshot do contrato, baixado de /v3/api-docs do backend
├── scripts/
│   └── regenerate_api_client.sh      # roda o openapi-generator sobre openapi/openapi.json
├── lib/
│   ├── core/
│   │   ├── theme/app_theme.dart      # ColorScheme.fromSeed verde, light + dark
│   │   ├── providers/auth_provider.dart
│   │   ├── services/
│   │   │   ├── dio_client.dart           # injeta o Dio (interceptor JWT) no client gerado
│   │   │   ├── storage_service.dart      # JWT + role + nome em SharedPreferences
│   │   │   └── notification_service.dart # FCM + flutter_local_notifications
│   │   └── widgets/                      # loading/erro/empty state compartilhados
│   ├── features/
│   │   ├── auth/            # login_screen, auth_service, auth_token (existente)
│   │   ├── student/
│   │   │   ├── screens/student_home_screen.dart
│   │   │   └── providers/list_provider.dart
│   │   ├── driver/
│   │   │   ├── screens/driver_home_screen.dart
│   │   │   └── providers/driver_provider.dart
│   │   └── admin/
│   │       ├── screens/ (routes, reports, users, broadcast)
│   │       └── providers/ (route_provider, report_provider, user_provider)
│   └── main.dart
├── test/
│   ├── unit/      # providers/services, client de API mockado
│   └── widget/    # telas principais
└── docs/
    └── superpowers/specs/   # este documento e futuros specs
```

### 4.2 Geração do client HTTP

- Ferramenta: `openapi-generator-cli`, generator **`dart-dio`**.
- Fonte: snapshot commitado em `openapi/openapi.json`, baixado manualmente de `GET /v3/api-docs` com o backend local rodando. Não gera direto de um backend ao vivo no build — build fica reprodutível sem depender do backend estar de pé.
- Regeneração é deliberada: rodar `scripts/regenerate_api_client.sh` sempre que o contrato do backend mudar.
- O pacote gerado (`packages/smartboarding_api_client`) é importado no app via `path:` no `pubspec.yaml`.
- `DioClient` (já existente) continua sendo a fonte da instância Dio com o interceptor de JWT — essa instância é passada para o client gerado, então autenticação não muda.
- Sem camada extra de mapeamento entre DTOs gerados e "domain models" próprios — providers e telas usam os models gerados diretamente (evita abstração prematura).

### 4.3 Estado

- **Provider** exclusivamente (convenção já definida no backend `CLAUDE.md`) — sem BLoC, sem Riverpod.
- Um provider por feature: `AuthProvider`, `ListProvider`, `DriverProvider`, `RouteProvider`, `ReportProvider`, `UserProvider`.

### 4.4 Navegação

- `Navigator` 1.0 com rotas nomeadas simples (como já está em `main.dart`), estendido para `/driver` e as subtelas do admin.
- Sem `go_router` — não há deep linking nem fluxo de navegação complexo que justifique a dependência extra.

### 4.5 Tema

- `ColorScheme.fromSeed(seedColor: <verde>, brightness: Brightness.light)` e a variante `dark` — gerado automaticamente pelo Material 3, sem paleta hardcoded.
- Light: fundo branco. Dark: fundo preto/escuro.

### 4.6 Armazenamento local

- `SharedPreferences` via `StorageService` (já existe): token JWT, role, nome completo.
- Nunca armazenar senha.

### 4.7 Ambientes / Base URL

- `--dart-define=API_BASE_URL=...` na hora do build/run, em vez de hardcoded.
- Emulador Android: `http://10.0.2.2:8080`.
- Dispositivo físico: IP da máquina de desenvolvimento na rede local.
- Produção: URL definitiva quando existir hospedagem.

---

## 5. Fluxos por Papel

### 5.1 Aluno (`STUDENT`)

**StudentHomeScreen**
- Carrega `GET /api/lists/today` ao abrir + pull-to-refresh.
- Para cada lista do dia: nome da rota, contagem de inscritos, status.
- Não inscrito + lista `OPEN` → botão "Entrar na Lista" → `POST /api/lists/{id}/entries`.
- Inscrito → botão "Sair da Lista" + indicador visual (ex: badge "Você está na lista") → `DELETE /api/lists/{id}/entries`.
- Sem lista `OPEN` (16:01–23:59) → mensagem "Nenhuma lista aberta no momento. Listas disponíveis de 00:00 às 16:00."
- Recebe notificações #1, #2 e #3 (push).
- Logout.

### 5.2 Motorista (`DRIVER`) — depende do Gap 1 e Gap 2 (seção 8)

**DriverHomeScreen**
- Seleciona a lista/rota do dia (dropdown — hoje normalmente só uma rota ativa).
- Mostra contagem atual de inscritos ativos daquela lista.
- Campo de mensagem opcional (default: "O ônibus está saindo da rodoviária, embarque em instantes!").
- Botão "Enviar notificação de saída" com diálogo de confirmação antes de enviar (evita envio acidental).
- Feedback pós-envio: "Notificação enviada para N alunos."
- Logout.

### 5.3 Administrador (`ADMIN`)

**AdminHomeScreen** — dashboard com cards:
- Gerenciar Rotas
- Ver Relatórios
- Enviar Notificação (broadcast manual)
- Gerenciar Usuários

**RouteListScreen / RouteFormScreen**
- Lista rotas ativas e inativas.
- Criar (`POST /api/routes`), editar (`PATCH /api/routes/{id}`), desativar (`DELETE /api/routes/{id}`, soft-delete).

**ReportsListScreen / ReportDetailScreen**
- Lista paginada (`GET /api/reports?page=&size=&sort=generatedAt,desc`): data, rota, total de inscritos.
- Detalhe (`GET /api/reports/{id}`): snapshot com nome/email dos inscritos no fechamento.

**BroadcastNotificationScreen**
- Campos: título, corpo.
- `POST /api/notifications/broadcast` → envia para todos os dispositivos registrados.

**UserManagementScreen**
- Lista usuários (`GET /api/users`, `GET /api/users/{id}`).
- Criar usuário (`POST /api/auth/register`): email, senha, nome completo, role (`STUDENT`/`DRIVER`*/`ADMIN`), campos opcionais (curso, instituição, telefone, endereço, data nascimento, data de expiração).

\* Role `DRIVER` só fica disponível no formulário depois do Gap 1 (seção 8) estar implementado no backend.

---

## 6. Firebase — Setup do Zero

Projeto Firebase ainda não existe. Fluxo recomendado (FlutterFire CLI, evita configuração manual de `google-services.json`):

1. `flutter create . --platforms=android,ios` — adiciona as pastas que faltam hoje no projeto (só existem `windows/`, `macos/`, `linux/`).
2. Criar o projeto no [Firebase Console](https://console.firebase.google.com).
3. `dart pub global activate flutterfire_cli` seguido de `flutterfire configure` — registra os apps Android/iOS automaticamente, baixa `google-services.json` / `GoogleService-Info.plist`, gera `lib/firebase_options.dart`.
4. Ativar a **Cloud Messaging API** no projeto Firebase.
5. Backend: gerar a Service Account JSON (Firebase Console → Configurações do projeto → Contas de serviço) e apontar `FIREBASE_CREDENTIALS_PATH` no `.env` do `smartboarding-api`.
6. Validar com um envio de teste pelo próprio Firebase Console antes de integrar a lógica do app.

**NotificationService (Flutter)**
```dart
// Após login bem-sucedido:
final messaging = FirebaseMessaging.instance;
await messaging.requestPermission();
final token = await messaging.getToken();
// POST /api/devices/token { token, platform: 'android' | 'ios' }

// Foreground:
FirebaseMessaging.onMessage.listen((message) {
  // Exibir via flutter_local_notifications
});

// Background/terminated:
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

- Logout deve chamar `DELETE /api/devices/token` (remove os tokens FCM do usuário).

---

## 7. Contratos de API — já existentes no backend

Referência resumida (contrato completo em `smartboarding-api/CONTEXT.md`). Formato padrão de resposta: sucesso `{ "data": ... }`, erro `{ "code": "...", "error": "..." }`.

| Método | Path | Acesso | Uso no app |
|---|---|---|---|
| POST | `/api/auth/login` | Público | Login |
| POST | `/api/auth/register` | ADMIN | Criar usuário |
| GET | `/api/users` / `/api/users/{id}` | ADMIN | Gerenciar usuários |
| GET / POST / PATCH / DELETE | `/api/routes` | Público (GET) / ADMIN (resto) | Gerenciar rotas |
| GET | `/api/lists/today` | Autenticado | Tela inicial do aluno/motorista |
| GET | `/api/lists/{id}` | Autenticado | Detalhe da lista |
| POST / DELETE | `/api/lists/{id}/entries` | Autenticado | Entrar/sair da lista |
| GET | `/api/lists/{id}/entries` | ADMIN | Listar inscritos |
| GET | `/api/reports` / `/api/reports/{id}` | ADMIN | Relatórios |
| POST | `/api/notifications/broadcast` | ADMIN | Notificação manual pra todos |
| POST / DELETE | `/api/devices/token` | Autenticado | Registro de push |

---

## 8. Gaps de Backend — contrato proposto (documentado, **não implementado nesta fase**)

### Gap 1 — Role `DRIVER`

- Adicionar `DRIVER` ao enum `Role` do domínio (`domain/user/entity/Role.java`).
- Sem migration de banco — a coluna `role` já é `VARCHAR(20)`.
- Permitir `DRIVER` como valor aceito em `POST /api/auth/register` (ADMIN-only).
- Ajustar `SecurityConfig` para as regras de acesso que a rota do motorista exigir (ver Gap 2).

### Gap 2 — Notificação de saída direcionada

```
POST /api/lists/{id}/notifications/departure   · DRIVER, ADMIN

Request (body opcional, com default se omitido):
{ "title": "Ônibus saindo!", "body": "O ônibus está saindo da rodoviária, embarque em instantes." }

Response 200:
{ "data": { "success": true, "notified": 12 } }
```

- Busca `list_entries` ativos (`is_active=true`) da `daily_list_id={id}`.
- Resolve os `device_tokens` dos usuários encontrados.
- Envia via FCM reaproveitando `FcmPort` / o mesmo mecanismo de `SendToUserUseCase` já existente (loop, não broadcast).
- Funciona independente do `status` da lista (`OPEN` ou `CLOSED`).
- Se não houver inscritos ativos: resposta de sucesso com `notified: 0` (não é erro).

### Gap 3 — Broadcast automático de "lista aberta"

- Dentro do job `openDailyLists()` (`@Scheduled(cron = "0 0 0 * * MON-FRI")`), adicionar uma chamada de broadcast FCM, no mesmo padrão que `closeDailyLists()` já faz às 16h.
- Mensagem sugerida: "A lista de embarque de hoje já está disponível! Inscreva-se até as 16h."

---

## 9. Estratégia de Testes

- **Unit tests**: um por provider (`AuthProvider`, `ListProvider`, `DriverProvider`, `RouteProvider`, `ReportProvider`, `UserProvider`), com o client de API mockado via `mocktail`. Cobrem: gating por status da lista, alternância entrar/sair, mapeamento de mensagens de erro, redirecionamento por papel após login.
- **Widget tests**: `LoginScreen` (validação/erro), `StudentHomeScreen` (estado vazio / inscrito / não inscrito), `DriverHomeScreen` (confirmação antes de enviar), formulários do Admin (validação de campos obrigatórios).
- **Manual**: fluxo completo no emulador Android (login → entrar na lista → notificação) antes de cada entrega.
- **iOS**: ver risco na seção 10 — sem Mac local, testes automatizados/manuais em iOS ficam dependentes de CI com runner macOS ou acesso físico a um Mac.

---

## 10. Riscos e Dependências

| Risco/Dependência | Impacto | Mitigação |
|---|---|---|
| Sem Mac disponível para build/teste iOS local (ambiente de dev é Windows) | Não dá pra validar iOS localmente | Usar CI com runner macOS (GitHub Actions/Codemagic) antes da entrega final, ou aceitar "compila mas não testado localmente" como risco conhecido |
| Gaps 1 e 2 de backend não implementados nesta fase | Fluxo do motorista não pode ser testado ponta a ponta | UI do motorista é construída mesmo assim; teste E2E fica bloqueado até os gaps serem resolvidos (recomendado não deixar para a última semana) |
| Gap 3 não implementado | Notificação de "lista aberta" não dispara automaticamente | App já fica pronto para recebê-la; só falta o backend enviar |
| Projeto Firebase ainda não existe | Nenhuma notificação funciona sem isso | Primeira tarefa da Fase 0 |

---

## 11. Fases de Implementação

| Fase | Conteúdo | Bloqueio |
|---|---|---|
| 0 | Setup: adicionar plataformas android/ios, criar projeto Firebase, gerar client OpenAPI, aplicar tema | — |
| 1 | Auth: ajustar `AuthProvider`/redirecionamento para os papéis `STUDENT`/`ADMIN` (DRIVER preparado, ver fase 5) | — |
| 2 | Fluxo do aluno: lista do dia, entrar/sair, mensagens de janela fechada | — |
| 3 | FCM: registro de device token, notificações de lista aberta/fechada (foreground/background) | Gap 3 para a notificação de abertura funcionar ponta a ponta |
| 4 | Fluxo Admin: rotas (CRUD), relatórios, broadcast manual, criar usuários | — |
| 5 | Fluxo Motorista (UI completa; teste ponta a ponta depende do backend) | Gaps 1 e 2 |
| 6 | Endurecimento: cobertura de testes, revisão de UX, polimento visual | — |

---

## 12. O que NÃO fazer (convenções herdadas do backend, válidas também aqui)

- Não hardcodar senha em nenhum lugar do client.
- Não editar o pacote `smartboarding_api_client` manualmente — sempre regenerar.
- Não adicionar `go_router`, BLoC ou Riverpod sem necessidade concreta que justifique a troca.
- Não criar telas de autocadastro — toda conta nasce pelo ADMIN.
- Não bloquear a notificação de saída (#3) por status de lista `CLOSED` — essa é a regra de negócio real (embarque acontece depois do fechamento).
