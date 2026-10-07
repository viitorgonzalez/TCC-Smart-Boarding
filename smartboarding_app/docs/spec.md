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
manualmente. Ninguém cria conta de `ADMIN`: acesso administrativo é concedido sobre uma
conta existente, na ficha do usuário (promover/rebaixar papel) — ver
`smartboarding-api/docs/spec.md` RN27.

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
- Uma rota atende várias instituições (RN15 do backend) — é essa divisão por instituição
  (`InstitutionBreakdown`, `lib/core/widgets/institution_breakdown.dart`) que o admin usa pra
  dimensionar o transporte.
- O card de rota (aluno e admin) mostra um mapa (`google_maps_flutter`, sem tempo real) com os
  pontos da rota — paradas comuns e pontos principais (rodoviária + instituições), cada um com
  ícone.

### 3.3 Lista diária

- Entrar/sair da lista só é permitido com a lista `OPEN`. Fora da janela, a tela mostra o
  horário real de fechamento daquela rota (não um horário fixo genérico — cada rota tem o seu).
- `DailyList.acceptsChanges` (não só `status == OPEN`) decide se o botão de entrar/sair aparece:
  a lista só vira `CLOSED` de fato na próxima varredura do agendador (até 5 min depois do
  horário) — olhar só o `status` deixaria o botão vivo nessa janela, e o toque morreria em `400
  LIST_CLOSED`. Horário de fechamento desconhecido (`closeTime` nulo) não é tratado como horário
  vencido: sem ele, vale só o `status`.
- Uma inscrição ativa por (aluno, lista do dia). Sair é soft-delete — o aluno pode reentrar na
  mesma lista, no mesmo dia, enquanto ela estiver aberta.
- Contagem de inscritos exibida = inscrições ativas.
- O tempo restante até o fechamento (`timeUntilListClose`,
  `lib/core/utils/date_format.dart`) é calculado a partir do UTC, nunca de `DateTime.now()`
  local: Brasil não tem horário de verão desde 2019 (UTC-3 fixo), mas o fuso configurado no
  aparelho pode mentir (ex.: emulador em GMT em vez de America/Sao_Paulo) mesmo com o relógio
  (epoch) certo. `.toUtc()` desfaz esse fuso errado e recupera o instante real, e só depois
  disso o offset fixo do Brasil é subtraído.

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
  emitido também para de valer na requisição seguinte: o backend lê o papel e o estado da
  conta no banco a cada chamada, não da claim do token — senão rebaixar ou desativar só
  faria efeito até uma hora depois.
- Um 401 é tratado diferente conforme a rota: em `/auth/*` quem está do outro lado ainda
  não tem sessão nenhuma, então o app mostra "e-mail ou senha incorretos" — falar em sessão
  expirada ali mandaria o usuário fazer o que já está fazendo. Fora de `/auth/*`, 401 é
  sessão vencida de verdade e cai no fluxo de reautenticação (abaixo).
- `AppException.fromError` prioriza a mensagem que vier no corpo da resposta (`error`/`message`)
  sobre o texto genérico do status: a API manda o motivo real ali, e cair no genérico esconderia
  justamente a informação útil (ex.: por que um `409` aconteceu). Erro que não é `AppException`
  nem `DioException` (bug interno, string solta etc.) sempre vira a mensagem genérica — nunca
  vaza detalhe de implementação pro usuário.
- O encerramento por sessão expirada acontece fora da árvore de widgets: o interceptor do
  `Dio` que lê o 401 não tem `BuildContext`, então ele chama um gancho estático
  (`DioClient.onUnauthorized`, ligado pelo `AuthProvider`) em vez de notificar o provider
  direto, e a navegação de volta ao login usa a `navigatorKey` global
  (`lib/core/navigation/app_navigator.dart`) pra desempilhar as telas abertas sobre o
  `AuthGate` — ele troca pra tela de login sozinho, mas é a tela de baixo, então sem
  desempilhar o que estava aberto por cima continuaria na frente.
- Encerrar a sessão (expirada, conta desativada ou removida) só avisar não basta: sem
  derrubar a sessão o usuário fica numa tela onde toda ação falha, lendo "faça login
  novamente" sem ter como. O `AuthProvider` guarda uma trava de reentrância
  (`_encerrando`) porque uma tela que dispara várias requisições ao mesmo tempo toma
  vários 401 de uma vez, e sem a trava cada um tentaria encerrar a sessão de novo.

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
- Listas paginadas pelo backend usam `PageResult<T>` (`lib/core/pagination/page_result.dart`)
  pra centralizar a leitura de `content`/`number`/`totalPages` do formato de página do Spring e
  decidir `hasMore` num lugar só — conta errada aqui trava o carregamento ou faz o app pedir
  páginas que não existem. No consumo, `InfiniteList` (`lib/core/pagination/infinite_list.dart`)
  pede a próxima página ao chegar a 400px do fim (pedir só ao encostar deixaria o usuário
  olhando a barra de carregamento a cada página); não há numeração de página na UI — pra quem
  usa é uma lista só que não baixa a base inteira pra mostrar os primeiros itens.

### 4.3 Estado

- `Provider` exclusivamente — sem BLoC, sem Riverpod. Um provider por feature: `AuthProvider`,
  `ListProvider`, `RouteProvider`, `InstitutionProvider`, `VehicleProvider`, `ReportProvider`,
  `NotificationProvider`, `RegistrationProvider`, `TripProvider`, `UserProvider` (só listagem).
- `AsyncValue<T>` (`lib/core/utils/async_value.dart`, estados `AsyncLoading`/`AsyncData`/
  `AsyncError`) substitui o padrão manual `bool _loading / String? _error / T? _data` nos
  providers que carregam dado assíncrono.
- `MembershipProvider` e `StudentListProvider` são registrados como
  `ChangeNotifierProxyProvider<AuthProvider, _>` em `main.dart`: a cada troca de sessão
  (`AuthProvider` notifica), `MembershipProvider.load()` recarrega e `StudentListProvider`
  recebe o e-mail da nova sessão — sem isso, trocar de conta (logout seguido de login de outra
  pessoa) faria quem loga a seguir herdar as rotas e a lista do dia da sessão anterior.

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
- `StorageService` cacheia a instância de `SharedPreferences` num estático, de propósito: o
  interceptor de JWT chama `getToken()` a cada requisição HTTP, e reabrir o storage todas as
  vezes seria desperdício. Em teste, isso exige um `clearAuth()` explícito entre casos — o
  cache sobrevive a `setMockInitialValues`, então sem limpar pela instância a sessão de um
  teste vaza pro próximo.

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
- `test/support/fake_http.dart` (`FakeHttpAdapter`/`installFakeHttp`) substitui só o
  **transporte** HTTP do `Dio` real — o interceptor de JWT e o de erro continuam rodando, então
  o teste exercita o caminho de verdade, inclusive a conversão de `DioException` em
  `AppException`. `installFakeHttp` sempre limpa a sessão via `StorageService().clearAuth()`
  explicitamente: `StorageService` cacheia a instância de `SharedPreferences` num estático (de
  propósito, pro interceptor não reabrir o storage a cada requisição), e esse cache sobrevive a
  `SharedPreferences.setMockInitialValues` — sem limpar pela própria instância, a sessão de um
  teste vaza pro próximo.
- Fixture de lista/rota em teste de widget evita cravar `closeTime`: com um horário fixo,
  `DailyList.acceptsChanges` vira falso depois dele e o card inteiro muda de aparência — o teste
  passaria de manhã e falharia à noite (ou vice-versa) dependendo da hora em que rodasse.
- Dentro de `testWidgets` o relógio é falso, e o `Dio` pendura a requisição nos timers de
  connect/receive — um `await` direto nunca voltaria. Testes que precisam de uma chamada de rede
  de verdade antes de montar a árvore (ex.: carregar um provider) usam `tester.runAsync(...)`
  pra isso, e depois montam o widget com `pump` de duração fixa em vez de `pumpAndSettle` quando
  a tela tem algo que anima pra sempre (ex.: um `CircularProgressIndicator` de estado "carregando
  o dia") — `pumpAndSettle` nesse caso nunca retornaria.
- `test/support/pump_until.dart` (`pumpUntil`) bombeia frames até uma condição valer, em vez de
  usar `pumpAndSettle` ou uma duração chutada: as requisições do `Dio` (mesmo com adaptador
  falso) só andam com tempo real, e parte da cadeia de `setState` só anda com o relógio falso do
  `testWidgets` avançando — nenhum dos dois sozinho basta, por isso o laço intercala `runAsync` e
  `pump`. O parâmetro `describe` entra na mensagem de falha; sem ele, estourar o teto de
  tentativas vira um timeout mudo.
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

## Perfil, endereço e carteirinha (set/2026)

### Entrar na lista exige perfil completo

`fullName`, `phone`, endereço completo e ao menos uma instituição (RN29 do backend). O card da
lista **avisa antes** de o aluno tocar no botão, nomeando o que falta — descobrir o bloqueio só
ao tocar é fazer a pessoa esbarrar numa parede que dava pra sinalizar.

Quem decide o que falta é o backend (`GET /api/me` → `missingForList`). Refazer a conta em Dart
daria duas versões da regra, e a que vale é a de quem recusa a entrada.

`MeProvider` é compartilhado entre o perfil e o card da lista: com duas cópias do `/me`, salvar
o telefone pelo cabeçalho deixaria o aviso do card mentindo até alguém reabrir a tela.

### Endereço por CEP

O aluno digita **CEP e número**; rua, bairro, cidade e UF chegam do ViaCEP.

O `CepService` constrói um **Dio próprio**, nunca o `DioClient`: aquele injeta o Bearer da sessão
em toda requisição, e reaproveitá-lo entregaria o token do aluno a um host de terceiro. Há teste
pra isso.

Armadilha do serviço: **CEP inexistente responde HTTP 200 com `{"erro": true}`** — e o campo já
veio como booleano e como string em versões diferentes. Olhar só o status deixaria o aluno salvar
endereço em branco achando que preencheu.

Sem SLA: falha devolve `null`, os campos seguem editáveis à mão, e um CEP que falha **não apaga**
o que já foi digitado.

O formulário consulta o ViaCEP a cada tecla digitada (sem debounce) — `CepService.lookup` só
dispara a requisição quando sobram exatamente 8 dígitos após limpar não-dígitos, então um CEP
incompleto não gera request fadado a 404. Uma letra digitada por engano também cai nesse corte:
ela some no filtro de dígitos e derruba a contagem pra menos de 8.

No `AddressCard`, o campo de CEP ganha um hífen enquanto se digita (`_CepFormatter`) — o teclado
numérico não tem tecla de hífen, e sem a máscara o campo mostraria `35570000` enquanto todo
mundo lê CEP como `35570-000`. Ao achar o endereço, o foco pula pro campo **Número**: é o único
dado que o ViaCEP não devolve, então é o único que falta a pessoa preencher. Os campos que
alimentam o aviso de "falta preencher" (CEP, rua, bairro, número) precisam reconstruir a tela a
cada tecla digitada — sem isso, quem completa o número à mão continuaria vendo o aviso em
vermelho e concluiria que o app travou; a busca do CEP já disparava esse rebuild, mas digitar
sem passar pelo ViaCEP não disparava. Os campos preenchidos pelo CEP continuam **editáveis**,
nunca travados: o que o ViaCEP traz é chute de base pública, e um CEP único compartilhado por
uma cidade pequena pode devolver a rua errada — travar o campo prenderia a pessoa nesse erro.

### Onde cada coisa salva

| Campo | Caminho |
|---|---|
| Instituição | `POST`/`DELETE /me/institutions/{id}` — direto, card e fluxo próprios (`MyInstitutionsCard`), fora da fila |
| Nome, telefone, curso, endereço | uma solicitação só (`POST /me/profile-requests`), fila de aprovação do admin |

Nome, telefone, curso e endereço entram **juntos** na mesma solicitação — tudo que decide ou
descreve a pessoa pro transporte passa pela mesma revisão, em vez de misturar "salva na hora"
com "espera aprovação" no mesmo formulário (o que confundiria sobre o que já valeu). `ProfileService`
ainda expõe `updateAddress`/`updateOwnProfile` (`PUT /me/address`, `PUT /me/profile`) de um
modelo anterior em que endereço/telefone/curso salvavam direto — hoje nenhuma tela chama esses
dois métodos; `AddressCard` e `OwnDataCard` só editam os `TextEditingController`s que o pai
(`ProfileScreen`) controla, e é a tela que decide quando enviar (um botão só, "Enviar para
aprovação"). O endereço vai **inteiro** no pedido, não só o campo que mudou: a aprovação aplica
o objeto todo de uma vez, e mandar só o número apagaria rua/bairro que a pessoa não tocou.
Instituição continua fora dessa fila, em card e fluxo próprios, porque é o único card que ainda
salva por conta própria. `Address.complete`/`shortForm`
também vêm calculados do backend, pelo mesmo motivo de `missingForList`: a regra de "endereço
completo" decide se o aluno entra na lista, e duas versões dela (uma em Java, outra em Dart)
divergiriam na primeira mudança. `Me.institution` guarda o **nome** da instituição principal,
não o id — quem lê isso é a carteirinha, e resolver o id ali obrigaria a tela a baixar o
catálogo inteiro só pra escrever uma linha.

### Pedidos de alteração de perfil (fila de aprovação)

Nome, telefone, curso e endereço não salvam direto (tabela acima) — entram como `ProfileUpdate`
na fila do admin (`ProfileRequestsScreen`). Regras do modelo:

- Campo nulo no pedido significa "não foi pedida mudança nele", não "pedir para ficar vazio" —
  distinguir os dois é o que evita apagar um dado que o aluno não quis tocar. Só os campos
  efetivamente pedidos (não nulos) aparecem no resumo de mudanças e no antes/depois que o admin
  vê.
- `ProfileUpdate.before` guarda o valor de cada campo **antes** do pedido, pra montar esse
  antes/depois; vem todo nulo quando a conta do aluno que pediu já não existe mais (conta
  apagada) — a tela trata isso mostrando "—", não erro.
- O endereço pedido chega **achatado** no corpo do pedido (`zipCode`/`street`/... direto no
  JSON), diferente de `GET /api/me`, que devolve endereço como objeto `address` aninhado — o
  parser dos dois lados (`ProfileUpdate` e `ProfileUpdate.before`) precisa tratar o formato
  achatado.
- Em `ProfileScreen`, os campos só são preenchidos com o que veio do `/me` **uma vez**
  (`_preenchidoDoMe`): depois disso é o que a pessoa está digitando, e sobrescrever a cada
  rebuild do `MeProvider` apagaria o que ela já escreveu. Só o que de fato mudou entra no pedido
  (`_mudouTexto`) — mandar tudo faria o admin revisar campos que a pessoa nem tocou.
- Enquanto a solicitação está `PENDING`, os campos do formulário ficam travados (`readOnly`):
  deixar editável sugeriria que dá pra mandar outro pedido, e o backend recusa com `409` enquanto
  o atual não for decidido.
- `MyInstitutionsCard` fica **acima** do formulário de perfil: sem instituição o aluno não entra
  em rota nenhuma, então é a primeira coisa que precisa resolver ao abrir a tela.
- `OwnDataCard`/`AddressCard` escutam os próprios `TextEditingController`s com `ListenableBuilder`
  em vez de depender de `setState` da tela: o controller é do pai (`ProfileScreen`), e reconstruir
  só o card — não a tela inteira — a cada tecla é o que evita recriar todo o formulário por
  caractere digitado.
- `MyInstitutionsCard` aceita **mais de uma** instituição por conta — quem faz dois cursos não
  precisa escolher qual declarar — mas a **primeira declarada é a principal**: é ela que decide
  em que contagem da lista o aluno entra (`Me.institution`). Pro admin, a mesma lista de
  instituições é o que permite restringir um código de convite a uma instituição específica.
- Trocar e-mail (`EmailCard`) é dois passos **visualmente separados** (pedir código, depois
  confirmar), diferente de `PasswordCard` (um formulário só): o campo de código só existe depois
  que o primeiro pedido já saiu, então mostrar os dois campos de uma vez deixaria o aluno
  encarando um campo de código que ele ainda nem recebeu. Depois de salvar uma senha nova
  (`PasswordCard`), os campos são limpos — deixar a senha digitada na tela exposta é dado
  sensível pra quem olhar o aparelho por cima do ombro.
- O aluno consulta o próprio pedido por dois endpoints com propósitos diferentes:
  `GET /me/profile-requests/pending` (nulo se não há nada `PENDING`) alimenta o estado "aguardando
  análise"; `GET /me/profile-requests/latest` traz o último pedido em **qualquer** estado — é por
  ele que a recusa e o motivo chegam até o aluno, já que o `/pending` some assim que o admin
  decide.
- `ProfileRequestsScreen` busca a fila inteira de uma vez e filtra na tela (pendentes/aprovados/
  rejeitados/todos) — a base de pedidos não cresce como a de usuários, então não precisa de
  paginação nem de um fetch por filtro.
- No antes/depois de cada pedido (`_DiffRow`), o valor antigo aparece riscado ao lado do novo —
  é a mesma convenção visual de "o que mudou" usada em outros diffs do app (ex.: motivo de
  recusa).
- `MeProvider.faltando` fica vazio enquanto `/me` ainda não carregou, de propósito: mostrar
  "falta preencher" antes de saber o que de fato falta acusaria de errado quem está com o
  perfil em ordem. Falha ao carregar `/me` também fica silenciosa — ele alimenta avisos, não a
  operação em si, e quebrar a tela inteira por um aviso que não carregou trocaria um incômodo
  por um bloqueio.

### Senha e e-mail

- Criar senha local (`POST /me/password`, de quem entrou só pelo Google) e trocar senha
  (`PUT /me/password`, de quem já tem uma) usam verbos HTTP diferentes de propósito: um cria a
  primeira senha, o outro substitui uma existente provando posse da antiga (`currentPassword`).
- Trocar e-mail é em duas etapas: `POST /me/email/request {newEmail}` manda um código de 6
  dígitos pro e-mail **novo**, pra provar posse dele; `POST /me/email/confirm {code}` aplica a
  troca se o código bater. A sessão atual para de valer logo depois de confirmar — o token
  carrega o e-mail antigo, e o servidor para de reconhecê-lo assim que a troca acontece, então a
  tela precisa reencaminhar pro login.
- `GET/POST/DELETE /me/institutions` (instituições do próprio aluno) vive sob `/me`, não na área
  do admin, porque é pré-requisito pra entrar em rota — é dado que o próprio aluno gerencia.
