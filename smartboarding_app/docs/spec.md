# SmartBoarding App (Flutter) — Especificação

> Escopo: app Flutter (`smartboarding_app/`). Descreve o app como ele **é** — arquitetura,
> papéis e regras de negócio no estado atual. Telas individuais: ver [`PAGES.md`](./PAGES.md)
> (índice) e `docs/specs/<tela>.md` (uma por tela). Contrato de backend completo:
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
3. Cadastro do aluno por convite, sem depender do admin digitar cada conta.
4. Rota resolvida automaticamente pela instituição do aluno, com mapa dos pontos.
5. Notificações push nos momentos certos: lista aberta, lista fechada, trajeto, mudança de regra
   de rota, e envio manual do admin.

### Fora de escopo

- Rastreamento em tempo real (GPS) do ônibus — o mapa mostra pontos fixos.
- Pagamento/cobrança.

---

## 2. Papéis e Permissões

| Papel | Quem é | Pode fazer |
|---|---|---|
| `STUDENT` | Aluno que usa o transporte | Autocadastro via convite, ver a lista do dia da própria rota, entrar/sair da lista, registrar device token, ver notificações, ver relatórios dos últimos 7 dias, "lembrar de mim" no login |
| `ADMIN` | Gestão do transporte (inclui quem dirige) | Gerar convite, aprovar/negar cadastros, gerenciar rotas/instituições/veículos/paradas, ver relatórios completos, enviar notificação (com imagem), ações de trajeto |

Conta de `STUDENT` nasce só pelo fluxo de convite (§3.1) — o admin não cadastra aluno
manualmente. `ADMIN` pode criar outro `ADMIN` diretamente, sem convite.

---

## 3. Regras de Negócio

Espelham `smartboarding-api/docs/spec.md` §4 — aqui, só o que muda na experiência do app.

### 3.1 Cadastro

- Aluno recebe e-mail com um App Link/Universal Link. Com o app instalado, abre direto na tela
  de cadastro, pré-preenchida com o e-mail do convite; sem o app, cai numa página web pedindo
  pra instalar. O aluno escolhe a instituição (dropdown das cadastradas) e submete.
- Cadastro fica "aguardando aprovação" até o admin decidir. Login antes da aprovação mostra
  mensagem dedicada, não erro genérico de credencial. Se negado, o aluno pode reenviar os dados
  pelo mesmo link, enquanto o token não expirar.

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

### 3.7 Sessão longa

- Checkbox "Lembrar de mim" no login. Quando marcado, o app guarda um refresh token (7 dias) e
  renova o JWT automaticamente antes de expirar, sem pedir login de novo dentro da janela.

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
│   ├── theme/app_theme.dart          # paleta (§4.5)
│   ├── providers/auth_provider.dart
│   ├── services/
│   │   ├── dio_client.dart           # Dio + interceptor JWT (+ refresh automático)
│   │   ├── storage_service.dart      # JWT + refresh token + role + nome
│   │   └── notification_service.dart # FCM + flutter_local_notifications
│   └── widgets/                      # loading/erro/empty state compartilhados
├── features/
│   ├── auth/            # login, registro por convite, esqueci/redefinir senha
│   ├── student/          # lista do dia, mapa, entrar/sair
│   ├── notifications/    # inbox (aluno+admin) + envio (admin, FAB)
│   └── admin/             # rotas, instituições, veículos, paradas, relatórios,
│                          # aprovações de cadastro, trajeto
└── main.dart
test/
├── unit/      # providers/services
└── widget/    # telas principais
docs/
├── spec.md          # este arquivo
├── PAGES.md         # índice de telas
└── specs/           # uma spec por tela
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

- `Navigator` 1.0 com rotas nomeadas simples — sem `go_router`. `/register/:token` recebe a
  entrada do App Link (§3.1).

### 4.5 Tema

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
sobrescrito por Dark Slate Grey, distinto do fundo Charcoal Blue.

### 4.6 Armazenamento local

- `SharedPreferences` via `StorageService`: JWT, refresh token, role, nome completo. Nunca
  armazenar senha.

### 4.7 Ambientes / Base URL

- `--dart-define=API_BASE_URL=...` no build/run. Emulador Android: `http://10.0.2.2:8080`.
  Dispositivo físico: IP da máquina na rede local. Produção: URL do Render.

---

## 5. Páginas

Ver [`PAGES.md`](./PAGES.md) para o índice completo (rota, acesso, contrato de API por tela) e
`docs/specs/<tela>.md` para o detalhe de cada uma.

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
- Toda integração nova (Resend, R2, refresh token, Google Maps) precisa estar funcionando de
  verdade antes de a task ser considerada pronta — não só mockada localmente (`main` é prod).

---

## 8. Riscos e Dependências

| Risco | Impacto | Mitigação |
|---|---|---|
| Sem Mac disponível para build/teste iOS local | Não dá pra validar iOS localmente | CI com runner macOS antes da entrega final, ou aceitar como risco conhecido |
| Cota gratuita do Google Maps Platform não é ilimitada | Uso real pode gerar custo se crescer | Validar consumo estimado; monitorar |
| Resend, Cloudflare R2 e refresh token sem histórico de uso no projeto | Falha de config só aparece em produção se não testado de ponta a ponta | Validar contra os serviços reais antes de mergear (§7) |

---

## 9. O que NÃO fazer

- Não hardcodar senha em nenhum lugar do client.
- Não adicionar `go_router`, BLoC ou Riverpod sem necessidade concreta que justifique a troca.
- Não deixar o admin criar `STUDENT` manualmente — conta de aluno nasce só por convite (§3.1).
- Não recriar uma tela/papel de motorista separado — trajeto é do `ADMIN` (§3.8).
- Não bloquear a notificação de trajeto por status de lista fechada (§3.4).
- Não passar de 300 linhas por arquivo `.dart` tocado num PR (§7).
- Não mergear integração externa (Resend/R2/refresh token/Maps) só testada localmente/mockada.
