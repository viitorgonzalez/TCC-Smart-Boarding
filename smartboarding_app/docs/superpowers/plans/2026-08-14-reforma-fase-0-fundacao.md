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

- [ ] **Step 1: Remover `isDriver` de `AuthProvider`**
  - Linha 19 hoje: `bool get isDriver => _token?.role == 'DRIVER';` — deletar. Confirmar que
    nenhum outro arquivo além de `auth_gate.dart` chama `isDriver` (grep antes de deletar).

- [ ] **Step 2: Simplificar `AuthGate`**
  ```dart
  case AuthStatus.authenticated:
    if (auth.isAdmin) return const AdminHomeScreen();
    return const StudentHomeScreen();
  ```
  - Remove o `import '../../features/driver/screens/driver_home_screen.dart';` e o `if
    (auth.isDriver) return const DriverHomeScreen();`.

- [ ] **Step 3: Deletar a feature `driver/` e o teste correspondente**
  - `lib/features/driver/` inteira + `test/unit/driver_provider_test.dart`.

- [ ] **Step 4: `flutter analyze` limpo + `flutter test` verde**
  - Confirmar que nada mais importa símbolos de `features/driver/` (o `analyze` pega import
    quebrado se sobrar referência).

---

### Task 2: Paleta de cores nova no tema

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Trocar o seed único por `ColorScheme` derivado da paleta (`docs/spec.md` §4.5)**
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

- [ ] **Step 2: `flutter analyze` limpo**

- [ ] **Step 3: Smoke visual manual**
  - `flutter run` no emulador, abrir `LoginScreen` e `StudentHomeScreen` em light e dark
    (`ThemeMode.system` — trocar o tema do SO ou forçar `themeMode: ThemeMode.dark` temporário
    pra testar), confirmar que texto/botões continuam legíveis nas duas paletas.

---

## Ordem recomendada

Task 1 e Task 2 são independentes — podem ser feitas em qualquer ordem ou em paralelo. Nenhuma
das duas depende do backend (Fase 0 do backend só é pré-requisito pras fases seguintes, 1-6, não
pra esta).
