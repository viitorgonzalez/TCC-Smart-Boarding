# Reforma — Fase 0: Fundação (Flutter) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar a base Flutter pra reforma (`docs/spec.md` §3, §4.5): remover o papel
`DRIVER` do app, aplicar a paleta de cores nova no tema. **O quality gate de tamanho de arquivo
(CI) é feito no plano do backend** (`smartboarding-api/docs/superpowers/plans/2026-08-14-reforma-fase-0-fundacao.md`,
Task 4) — `.github/workflows/ci.yml` é compartilhado entre os dois apps, não duplicar aqui.

**Architecture:** Sem mudança — `Provider` por feature, services manuais em cima do `Dio`. Ver
`docs/spec.md` §4.

**Tech Stack:** Flutter 3.44+/Dart 3.12+, `provider`. Confirmado nesta sessão: o app **não** usa
`Navigator` com rotas nomeadas hoje (`main.dart` não tem `routes:` no `MaterialApp`) — a escolha
de tela por papel é feita direto em `AuthGate` (`lib/core/widgets/auth_gate.dart`), um
`switch`/if-chain sobre `AuthProvider.isAdmin`/`isDriver`. Isso corrige a menção a rotas nomeadas
tipo `/driver` que apareceu no `docs/spec.md` §4.4 — ajustar a spec se este plano for a fonte de
verdade da implementação real (nota pro fim desta fase, não uma task).

## Global Constraints

- **Sem comentários no código**, exceto pra explicar correção de bug muito específico.
- **Quality gate de 300 linhas/arquivo já vale a partir desta fase** (feito no plano do
  backend) — `student_home_screen.dart` (497 linhas) e `user_management_screen.dart` (387
  linhas) já excedem hoje; o gate só falha se esses arquivos aparecerem no diff de um PR. Não
  tocar neles nesta fase além do estritamente necessário (evitar disparar o gate antes da hora).

---

### Task 1: Remover papel `DRIVER` do app

**Files:**
- Delete: `lib/features/driver/` (pasta inteira: `screens/driver_home_screen.dart`,
  `services/driver_service.dart`, `providers/driver_provider.dart`)
- Delete: `test/unit/driver_provider_test.dart`
- Modify: `lib/core/providers/auth_provider.dart` (remover getter `isDriver`)
- Modify: `lib/core/widgets/auth_gate.dart` (remover import/branch de `DriverHomeScreen`)
- Modify: `lib/main.dart` (nenhuma mudança esperada — não registra `DriverProvider` no
  `MultiProvider` hoje; confirmar antes de assumir)

- [x] **Step 1: Remover `isDriver` de `AuthProvider`**
  - Linha 19 hoje: `bool get isDriver => _token?.role == 'DRIVER';` — deletar. Confirmar que
    nenhum outro arquivo além de `auth_gate.dart` chama `isDriver` (grep antes de deletar).

- [x] **Step 2: Simplificar `AuthGate`**
  ```dart
  case AuthStatus.authenticated:
    if (auth.isAdmin) return const AdminHomeScreen();
    return const StudentHomeScreen();
  ```
  - Remove o `import '../../features/driver/screens/driver_home_screen.dart';` e o `if
    (auth.isDriver) return const DriverHomeScreen();`.

- [x] **Step 3: Deletar a feature `driver/` e o teste correspondente**
  - `lib/features/driver/` inteira + `test/unit/driver_provider_test.dart`.

- [x] **Step 4: `flutter analyze` limpo + `flutter test` verde**
  - Confirmar que nada mais importa símbolos de `features/driver/` (o `analyze` pega import
    quebrado se sobrar referência).

---

### Task 2: Paleta de cores nova no tema

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [x] **Step 1: Trocar o seed único por `ColorScheme` derivado da paleta (`docs/spec.md` §4.5)**
  ```dart
  class AppTheme {
    static const _ashGrey = Color(0xFFCAD2C5);      // fundo light
    static const _mutedTeal = Color(0xFF84A98C);    // verde geral
    static const _deepTeal = Color(0xFF52796F);     // verde geral / seed
    static const _darkSlate = Color(0xFF354F52);     // tom escuro de apoio
    static const _charcoalBlue = Color(0xFF2F3E46);  // fundo dark

    static ThemeData get light => _base(Brightness.light);
    static ThemeData get dark => _base(Brightness.dark);

    static ThemeData _base(Brightness brightness) {
      final isDark = brightness == Brightness.dark;
      final scheme = ColorScheme.fromSeed(
        seedColor: _deepTeal,
        brightness: brightness,
        secondary: _mutedTeal,
      ).copyWith(
        surface: isDark ? _charcoalBlue : _ashGrey,
        surfaceContainerHighest: isDark ? _darkSlate : _ashGrey,
      );
      return ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: scheme.surface,
        // ...resto do ThemeData atual sem mudança (appBarTheme, cardTheme, etc.)
      );
    }
  }
  ```
  - ⚠️ Esqueleto — validar visualmente (`flutter run`, olhar as duas telas de exemplo em light e
    dark) antes de considerar pronto; `ColorScheme.fromSeed(...).copyWith(...)` pode gerar
    combinações de contraste ruins dependendo de onde `surfaceContainerHighest` acaba sendo usado
    (ex.: `inputDecorationTheme` já usa `scheme.surfaceContainerHighest.withValues(alpha: 0.3)`
    hoje — testar que o campo de texto continua legível).
  - Detalhamento fino de tema fica pro `/design-prompt` quando as telas novas da reforma forem
    desenhadas (`docs/spec.md` §4.5 já registra isso) — esta task só troca os tokens de cor base.

- [x] **Step 2: `flutter analyze` limpo**

- [ ] **Step 3: Smoke visual manual**
  - `flutter run` no emulador, abrir `LoginScreen` e `StudentHomeScreen` em light e dark
    (`ThemeMode.system` — trocar o tema do SO ou forçar `themeMode: ThemeMode.dark` temporário
    pra testar), confirmar que texto/botões continuam legíveis nas duas paletas.

---

### Task 3: Fundação do design system (tokens + componentes compartilhados)

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (`AppRadius`, `GoogleFonts.montserratTextTheme`)
- Modify: `pubspec.yaml` (`google_fonts`)
- Create: `lib/core/models/trip_type.dart` (movido de `lib/features/lists/models/`)
- Create: `lib/core/widgets/{empty_state,error_state,trip_type_chip,status_pill,entity_list_tile,loading_filled_button,initials_avatar,snackbar_utils}.dart`
- Modify: `lib/core/widgets/async_builder.dart` + ~10 telas (consumo dos widgets novos —
  `admin_home_screen`, `student_home_screen`, `routes_screen`, `route_form_screen`,
  `reports_screen`, `report_detail_screen`, `admin_list_entries_screen`,
  `user_management_screen`, `login_screen`, `broadcast_screen`)
- Modify: `docs/spec.md` §4.5 (tokens + tabela de componentes promovidos/watchlist)

- [x] **Step 1: Tokens** — `AppRadius.card`/`control` nomeados (substituem `12`/`10` literais);
  `google_fonts` adicionado (`flutter pub add google_fonts`); Montserrat aplicado via
  `GoogleFonts.montserratTextTheme(base.textTheme)` sobre o `ThemeData` já montado.
- [x] **Step 2: Mover `trip_type.dart` pra `core/models/`** — corrige a direção de dependência
  (`core` não deveria depender de `features`); 3 imports atualizados.
- [x] **Step 3: Criar os 8 componentes compartilhados** — regra de promoção: só o que tem 2+
  ocorrências reais hoje (levantamento via agent, não hipotético). `tone` do `StatusPill` mapeia
  pro `ColorScheme` existente (`primary`/`surfaceContainerHighest`/`error`), sem cor nova.
- [x] **Step 4: Consumir nas telas** — cada uma só trocou a implementação privada duplicada pela
  pública, sem mudar comportamento visual. Efeito colateral positivo: `student_home_screen.dart`
  caiu de 497 pra 445 linhas (ainda acima do limite de 300 do gate — não é escopo desta task
  zerar isso, só não piorar). Bônus fora do escopo original mas corrigido por estar no arquivo:
  `user_management_screen.dart` ainda listava `'DRIVER'` na hierarquia de papéis/formulário de
  criação — resquício da Task 1 que não pegou este arquivo; removido (`Role` no backend já não
  tem mais `DRIVER`, criar usuário com esse papel quebraria).
- [x] **Step 5: `flutter analyze` limpo + `flutter test` verde** — suíte atual (3 testes) sem
  regressão.
- [x] **Step 6: Documentar em `docs/spec.md` §4.5`** — tokens completos + tabela de componentes
  promovidos + watchlist (`InfoRow`, `InlineStatusBanner`, `FilterChipBar`, `SectionHeader`,
  `showConfirmDeleteDialog` — 1 ocorrência hoje, promove quando a 2ª aparecer).
- [ ] **Step 7: Smoke visual manual** — `flutter run`, `LoginScreen` e `StudentHomeScreen` em
  light e dark, confirmar Montserrat carregando e os componentes com a mesma aparência de antes.

---

## Ordem recomendada

Task 1 e Task 2 são independentes — podem ser feitas em qualquer ordem ou em paralelo. Nenhuma
das duas depende do backend (Fase 0 do backend só é pré-requisito pras fases seguintes, 1-6, não
pra esta). Task 3 depende de Task 2 estar pronta (paleta fechada, `docs/spec.md` §4.5 existente)
— feita depois, mesma sessão.
