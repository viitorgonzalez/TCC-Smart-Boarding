# SmartBoarding App (Flutter) — Especificação

> Escopo: app Flutter (`smartboarding_app/`). Descreve o app como ele **é** — arquitetura,
> papéis e regras de negócio no estado atual. Telas individuais: ver [`PAGES.md`](./PAGES.md)
> (índice) e `docs/specs/<categoria>/<tela>.md` (uma por tela). Contrato de backend completo:
> `smartboarding-api/docs/spec.md`.

---

## 1. Visão Geral

### Problema

O controle de embarque no ônibus universitário hoje é feito manualmente por grupo de WhatsApp:
nome escrito na lista por mensagem, fechamento por aviso humano, contagem manual de vagas, sem
aviso automático de saída do ônibus. Sujeito a erro e não escala.

### Objetivo do app

1. Lista diária com abertura/fechamento automáticos por horário (backend).
2. Contagem de inscritos em tempo real, sem digitação manual.
3. Autocadastro do aluno, sem depender do admin digitar cada conta.
4. Acesso à rota por código distribuído pelo admin, com mapa dos pontos.
5. Notificações push nos momentos certos: lista aberta, lista fechada, trajeto, mudança de regra
   de rota, e envio manual do admin.

### Fora de escopo

- Rastreamento em tempo real (GPS) do ônibus — o mapa mostra pontos fixos.
- Pagamento/cobrança.

---

## 2. Papéis e Permissões

| Papel | Quem é | Pode fazer |
|---|---|---|
| `STUDENT` | Aluno que usa o transporte | Autocadastro, entrar na rota com código, ver a lista do dia das próprias rotas, entrar/sair da lista, registrar device token, ver notificações, ver relatórios dos últimos 7 dias |
| `ADMIN` | Gestão do transporte (inclui quem dirige) | Gerar e revogar código de rota, aprovar/negar pedidos de alteração de perfil, gerenciar rotas/instituições/veículos/paradas, ver relatórios completos, enviar notificação (com imagem), ações de trajeto |

Conta de `STUDENT` nasce pelo autocadastro (§3.1) — o admin não cadastra aluno
manualmente. `ADMIN` pode criar outro `ADMIN` diretamente.

---

## 3. Regras de Negócio

Espelham `smartboarding-api/docs/spec.md` §4 — aqui, só o que muda na experiência do app.

### 3.1 Cadastro e entrada na rota

Detalhe completo em [`specs/autenticacao/signup-e-entrada-na-rota.md`](./specs/autenticacao/signup-e-entrada-na-rota.md).

- O aluno cria a conta sozinho, com nome, e-mail e senha — ou entra com Google. A conta
  nasce **sem rota**: existir no sistema e pertencer a uma rota são etapas separadas.
- Antes de entrar numa rota ele precisa declarar ao menos uma **instituição** no perfil.
  Sem isso a API recusa com `PROFILE_INCOMPLETE` — a instituição é o que diz onde ele
  desce e em que contagem entra.
- O acesso vem de um **código de rota** que o admin gera e distribui, no modelo do
  Classroom. O código tem validade e pode ser revogado, e o aluno pode estar em mais de
  uma rota.
- Quem entrou pelo Google pode criar uma senha local depois e passa a ter os dois
  caminhos de entrada.

### 3.2 Rota e instituição

- O aluno nunca escolhe rota — ela é derivada da instituição escolhida no cadastro. A tela
  inicial mostra só a lista da rota resolvida.
- O card de rota (aluno e admin) mostra um mapa (`google_maps_flutter`, sem tempo real) com os
  pontos da rota — paradas comuns e pontos principais (rodoviária + instituições), cada um com
  ícone.

### 3.3 Lista diária

- Entrar/sair da lista só é permitido com a lista `OPEN`. Fora da janela, a tela mostra o
  horário real de fechamento daquela rota (não um horário fixo genérico — cada rota tem o seu).
- Uma inscrição ativa por (aluno, lista do dia). Sair é soft-delete — o aluno pode reentrar na
  mesma lista, no mesmo dia, enquanto ela estiver aberta.
- Contagem de inscritos exibida = inscrições ativas.

### 3.4 Notificações

Cinco tipos, todos com histórico persistido (tela de notificações, visível a `ADMIN` e
`STUDENT`):

| # | Notificação | Gatilho | Destinatários |
|---|---|---|---|
| 1 | Lista aberta | Automático, abertura do dia (00:00) | Todos |
| 2 | Lista fechada | Automático, no `closeTime` de cada rota | Todos |
| 3 | Trajeto | Manual — `ADMIN`, ao iniciar/passar por ponto principal/finalizar | Inscritos ativos da lista do dia |
| 4 | Regra de rota mudou | Automático, ao editar uma rota | Vinculados àquela rota (via instituição) |
| 5 | Manual | Manual — `ADMIN`, via FAB | Geral ou uma rota específica, com imagem opcional |

A notificação de trajeto (#3) não depende do `status` da lista — dispara mesmo com a lista já
fechada, porque o embarque físico acontece depois do fechamento.

### 3.5 Relatórios

- `ADMIN` vê o histórico completo, paginado, com o veículo proposto (calculado pelo backend).
- `STUDENT` só vê os últimos 7 dias.

### 3.6 Expiração de conta

- `expiryDate` é a validade da carteirinha física de transporte. Login ou entrada na lista com a
  conta expirada mostram a mensagem "Sua carteirinha de transporte expirou — procure o
  administrador", não o erro genérico de credencial/permissão. `expiryDate = null` (comum em
  `ADMIN`) nunca expira.

### 3.7 Sessão

- O JWT vale **1 hora** e não há refresh token: expirou, entra de novo. "Lembrar de
  mim" e renovação automática foram desenhados e **nunca implementados** — se voltarem
  à mesa, entram como trabalho novo, não como algo a consertar.
- Conta desativada pelo admin não entra, nem por senha nem pelo Google. O token já
  emitido continua válido até expirar.

### 3.8 Trajeto

- Ações de trajeto (iniciar, checkpoint, finalizar) ficam dentro do painel do `ADMIN` — não
  existe uma conta/tela de motorista separada.
- Um botão de checkpoint por ponto principal da rota (rodoviária + instituições). Paradas comuns
  não geram botão, só aparecem no mapa. Cada ação pede confirmação antes de enviar.

---

## 4. Arquitetura Flutter

### 4.1 Estrutura de pastas

```
lib/
├── core/
│   ├── constants/                    # api_constants, auth_constants
│   ├── errors/app_exception.dart
│   ├── models/
│   ├── providers/auth_provider.dart
│   ├── services/
│   │   ├── dio_client.dart           # Dio + interceptor de JWT e de erro
│   │   ├── storage_service.dart      # JWT + papel + nome + e-mail
│   │   └── notification_service.dart # FCM (desligado até configurar o Firebase)
│   ├── theme/app_theme.dart          # paleta (§4.5)
│   ├── utils/async_value.dart        # AsyncLoading | AsyncData | AsyncError
│   └── widgets/                      # card, header, botões, estados compartilhados
├── features/
│   ├── auth/            # login, cadastro, Google, esqueci/redefinir senha
│   ├── membership/      # entrar na rota por código, sair, seletor de rota
│   ├── profile/         # perfil, instituições do aluno, pedido de alteração
│   ├── home/            # painel do aluno e painel do admin
│   ├── lists/           # lista do dia, inscritos
│   ├── routes/          # rotas, paradas, veículos
│   ├── institutions/    # catálogo de instituições
│   ├── trip/            # conduzir trajeto (ida e volta)
│   ├── users/           # usuários, ficha do aluno, ativar/desativar
│   ├── notifications/   # inbox (aluno+admin) + envio (admin)
│   ├── reports/         # relatórios e histórico de presença
│   ├── warnings/        # advertências
│   └── admin/           # estatísticas do painel
└── main.dart
test/
├── unit/      # providers/services
└── widget/    # telas principais
docs/
├── spec.md          # este arquivo
├── PAGES.md         # índice de telas
├── firebase-setup.md
├── specs/           # uma spec por tela, agrupada por categoria (autenticacao/aluno/
│                    # notificacoes/relatorios/administrador — espelha as seções do PAGES.md)
└── design/          # design-system.md (tokens) + design-prompts/ (prompts de layout,
                      # mesma categorização) + figma-screens/ (referência visual)
```

### 4.2 Client HTTP

- Services manuais em cima do `Dio` — sem client gerado por OpenAPI. `DioClient` injeta o
  interceptor de JWT e, quando a sessão longa está ativa (§3.7), tenta `POST /api/auth/refresh`
  automaticamente antes de forçar logout.

### 4.3 Estado

- `Provider` exclusivamente — sem BLoC, sem Riverpod. Um provider por feature: `AuthProvider`,
  `ListProvider`, `RouteProvider`, `InstitutionProvider`, `VehicleProvider`, `ReportProvider`,
  `NotificationProvider`, `RegistrationProvider`, `TripProvider`, `UserProvider` (só listagem).

### 4.4 Navegação

- `Navigator` 1.0, sem `go_router` — o app não tem deep link. Telas abrem por
  `Navigator.push`, e o push nasce no Navigator: provider criado na tela que empurra
  **não** chega na tela empurrada, tem que ser repassado explicitamente.

### 4.5 Design system — tokens e componentes

Inspirado na organização de `packages/tailwind-config` + `packages/ui` de um front web irmão
(tokens únicos + dois níveis de componente) — adaptado pro Flutter: não existe "primitive a
instalar" (Material 3 já dá `Card`/`ListTile`/`Chip`/`AlertDialog`...), então a camada que falta é
só **tokens completos** e **componentes do produto** (`lib/core/widgets/`).

**Cor**

| Tom | Hex | Uso |
|---|---|---|
| Ash Grey | `#CAD2C5` | Fundo do tema light |
| Muted Teal | `#84A98C` | Verde de uso geral |
| Deep Teal | `#52796F` | Verde de uso geral / seed do `ColorScheme` |
| Dark Slate Grey | `#354F52` | Tom escuro de apoio (dark) |
| Charcoal Blue | `#2F3E46` | Fundo do tema dark |

`ColorScheme` derivado desses 5 tons via `ColorScheme.fromSeed` (seed = Deep Teal) com `surface`
sobrescrito por tema. No light, `surfaceContainerHighest` fica com o valor derivado do seed (não
igualado ao fundo, senão o preenchimento dos inputs some contra a página); no dark, é
sobrescrito por Dark Slate Grey, distinto do fundo Charcoal Blue. Tons semânticos (`positive`/
`neutral`/`danger` — ver `StatusPill` abaixo) mapeiam direto pro `ColorScheme` existente
(`primary`/`surfaceContainerHighest`/`error`), sem token novo — não existe hoje nenhum uso real de
um 4º tom ("warning"); só criar se aparecer necessidade concreta.

**Tipografia:** Montserrat via `google_fonts` (`GoogleFonts.montserratTextTheme`, aplicado sobre o
`TextTheme` já derivado do `colorScheme` — preserva as cores de texto por brightness). Sem
`TextTheme` customizado além da fonte — a escala é a do Material 3.

**Raio:** nomeado em `AppRadius` (`lib/core/theme/app_theme.dart`) — `card = 12.0` (cards, list
tiles), `control = 10.0` (botões, campos). Não crava literal solto no `ThemeData`.

**Componentes do produto** (`lib/core/widgets/`) — promovidos pela regra "usado em 2+ telas hoje,
com evidência real" (mirror da regra do front web irmão, "usado em 2+ apps → compartilhado"):

| Widget | Cobre |
|---|---|
| `EmptyState` | Estado vazio (ícone + título + subtítulo opcional) |
| `ErrorState` | Estado de erro (ícone + mensagem + retry opcional) — usado internamente por `AsyncBuilder` |
| `StatusPill` | Selo de status (`tone`: positive/neutral/danger) |
| `EntityListTile` | Linha de lista (`Card`+`ListTile`: leading/title/subtitle/trailing) |
| `TripTypeChip` | Chip de direção de viagem (ida/volta) |
| `InitialsAvatar` | Avatar circular com inicial/índice |
| `LoadingFilledButton` | Botão que troca pra spinner durante ação assíncrona |
| `showErrorSnackBar` (helper) | SnackBar de erro consistente (`colorScheme.error`, não `Colors.red` hardcoded) |

**Watchlist** (candidatos com só 1 ocorrência hoje — promove quando a 2ª aparecer, não antes):
`InfoRow` (label:valor), `InlineStatusBanner` (banner colorido inline, ex.: contagem regressiva),
`FilterChipBar` (chips de filtro roláveis com contagem), `SectionHeader` (cabeçalho de seção
agrupada), `showConfirmDeleteDialog` (confirmação destrutiva).

### 4.6 Armazenamento local

- `SharedPreferences` via `StorageService`: JWT, papel, nome e e-mail. Nunca armazenar senha.

### 4.7 Ambientes / Base URL

- `--dart-define=API_BASE_URL=...` no build/run. Emulador Android: `http://10.0.2.2:8080`.
  Dispositivo físico: IP da máquina na rede local. Produção: URL do Render.

---

## 5. Páginas

Ver [`PAGES.md`](./PAGES.md) para o índice completo (rota, acesso, contrato de API por tela) e
`docs/specs/<categoria>/<tela>.md` para o detalhe de cada uma.

---

## 6. Firebase

Fluxo de setup (`flutterfire_cli`), sem passo interativo automatizável (login Google é manual):

1. `flutter create . --platforms=android,ios` (já feito).
2. Criar o projeto no Firebase Console.
3. `flutterfire configure` — registra os apps, baixa `google-services.json`/
   `GoogleService-Info.plist`, gera `lib/firebase_options.dart`.
4. Ativar a Cloud Messaging API.
5. Backend: gerar a Service Account JSON e apontar `FIREBASE_CREDENTIALS_PATH`.

**NotificationService**: registra o token FCM após login (`POST /api/devices/token`), escuta
mensagens em foreground via `flutter_local_notifications`, trata background/terminated via
`onBackgroundMessage`. Logout chama `DELETE /api/devices/token`.

---

## 7. Estratégia de Testes

- Unit tests por provider, com o client de API mockado via `mocktail`.
- Widget tests das telas principais (login, home do aluno, formulários do admin).
- Manual: fluxo completo no emulador Android antes de cada entrega.
- iOS: sem Mac local — validação automatizada/manual depende de CI com runner macOS ou acesso a
  um Mac físico.
- **Quality gate de cobertura** — `flutter test --coverage`, mesmo mecanismo de ratchet do
  backend (`.coverage-baseline`, regressão falha o build).
- **Quality gate de tamanho de arquivo** — nenhum arquivo `.dart` de produção (`lib/`) tocado num
  PR passa de 300 linhas.
- Sem comentários no código, exceto pra explicar correção de bug muito específico.
- Toda integração nova (Resend, R2, Google Sign-In, Google Maps) precisa estar funcionando de
  verdade antes de a task ser considerada pronta — não só mockada localmente (`main` é prod).

---

## 8. Riscos e Dependências

| Risco | Impacto | Mitigação |
|---|---|---|
| Sem Mac disponível para build/teste iOS local | Não dá pra validar iOS localmente | CI com runner macOS antes da entrega final, ou aceitar como risco conhecido |
| Cota gratuita do Google Maps Platform não é ilimitada | Uso real pode gerar custo se crescer | Validar consumo estimado; monitorar |
| Resend, Cloudflare R2 e Google Sign-In sem histórico de uso no projeto | Falha de config só aparece em produção se não testado de ponta a ponta | Validar contra os serviços reais antes de mergear (§7) |

---

## 9. O que NÃO fazer

- Não hardcodar senha em nenhum lugar do client.
- Não adicionar `go_router`, BLoC ou Riverpod sem necessidade concreta que justifique a troca.
- Não deixar o admin criar `STUDENT` manualmente — conta de aluno nasce por autocadastro (§3.1).
- Não recriar uma tela/papel de motorista separado — trajeto é do `ADMIN` (§3.8).
- Não bloquear a notificação de trajeto por status de lista fechada (§3.4).
- Não passar de 300 linhas por arquivo `.dart` tocado num PR (§7).
- Não mergear integração externa (Resend/R2/Google/Maps) só testada localmente/mockada.
