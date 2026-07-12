# Front — Tema Verde, Fluxo do Motorista, Gestão de Usuários e Preparo de Push — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar os gaps de frontend do app SmartBoarding em relação à `docs/spec.md`: aplicar o tema verde (light + dark), construir o fluxo do Motorista (DRIVER), adicionar a Gestão de Usuários no Admin e deixar o push (Firebase) estruturado para ativação futura — mantendo o app compilando e rodável a cada passo.

**Architecture:** Mantém a arquitetura já existente — `Provider` por feature, services manuais em cima do `Dio` (com interceptor JWT via `DioClient`), estado `AsyncValue<T>` + `AsyncBuilder`, navegação com `Navigator` 1.0 e `AuthGate` roteando por papel. Nenhum client gerado (decisão revisada de 2026-07-11 na spec). Cada nova feature segue o par service→provider→screen já usado em `routes/` e `reports/`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, `provider`, `dio`, `shared_preferences`, `mocktail` (novo, dev) para testes de provider.

## Global Constraints

- **Estado:** somente `Provider` (`ChangeNotifier`). Sem BLoC, Riverpod, go_router.
- **Client HTTP:** services manuais em cima de `DioClient.instance`. NÃO adicionar openapi-generator nem editar client gerado (não existe).
- **Formato de resposta da API:** sucesso `{ "data": ... }`, erro `{ "code": "...", "error": "..." }`. Todo service lê `response.data['data']`.
- **Tema:** seed **verde**, Material 3 (`useMaterial3: true`). Light = fundo branco, Dark = fundo preto/escuro. Sem paleta hardcoded além do seed.
- **Papéis:** `STUDENT`, `DRIVER`, `ADMIN` (strings). Sem autocadastro — toda conta nasce via `POST /api/auth/register` (ADMIN-only).
- **Senha:** mínimo 6 caracteres. Nunca armazenar senha localmente.
- **Regra do motorista:** a notificação de saída (#3) NÃO depende do status da lista — pode ser enviada com a lista `OPEN` ou `CLOSED`.
- **Base URL:** via `ApiConstants.baseUrl` (hoje `http://10.0.2.2:8080` para emulador Android). Não hardcodar em outro lugar.
- **Backend pendente:** endpoint `POST /api/lists/{id}/notifications/departure` (Gap 2) e role `DRIVER` no register (Gap 1) ainda não existem no backend. A UII do motorista é construída mesmo assim; o teste ponta a ponta fica bloqueado até os gaps, mas o app compila e o fluxo é navegável.

---

### Task 1: Tema verde (light + dark) + wiring do themeMode

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (reescrever para light + dark, seed verde)
- Modify: `lib/main.dart:34-39` (adicionar `darkTheme` + `themeMode`)
- Modify: `lib/features/auth/screens/login_screen.dart:60-61` (cor do ícone → tema)

**Interfaces:**
- Produces: `AppTheme.light` (`ThemeData`), `AppTheme.dark` (`ThemeData`) — consumidos por `main.dart`.

- [ ] **Step 1: Reescrever `app_theme.dart` com seed verde e variante dark**

Substituir todo o conteúdo de `lib/core/theme/app_theme.dart` por:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF2E7D32); // verde (Material Green 800)

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(space: 1),
    );
  }
}
```

- [ ] **Step 2: Wire `darkTheme` + `themeMode` no `main.dart`**

Em `lib/main.dart`, no `MaterialApp` (linhas ~34-39), trocar:

```dart
      child: MaterialApp(
        title: 'Smart Boarding',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
```

por:

```dart
      child: MaterialApp(
        title: 'Smart Boarding',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
```

- [ ] **Step 3: Ícone do login usa a cor do tema (não azul hardcoded)**

Em `lib/features/auth/screens/login_screen.dart` (linhas ~60-61), trocar:

```dart
                const Icon(Icons.directions_bus_rounded,
                    size: 72, color: Colors.blueAccent),
```

por:

```dart
                Icon(Icons.directions_bus_rounded,
                    size: 72, color: Theme.of(context).colorScheme.primary),
```

- [ ] **Step 4: Verificar que compila e o tema aplica**

Run: `flutter analyze`
Expected: sem novos erros (os 3 `unnecessary_underscores` pré-existentes podem continuar; serão tratados na Task 5).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/main.dart lib/features/auth/screens/login_screen.dart
git commit -m "feat(theme): tema verde com light+dark e themeMode system"
```

---

### Task 2: Fluxo do Motorista (DRIVER)

Constrói service, provider (com teste unitário TDD), tela e o roteamento por papel. Deliverable: logar como `DRIVER` abre a `DriverHomeScreen`, que lista as listas do dia, deixa selecionar uma, escrever mensagem e enviar a notificação de saída com diálogo de confirmação.

**Files:**
- Create: `lib/features/driver/services/driver_service.dart`
- Create: `lib/features/driver/providers/driver_provider.dart`
- Create: `lib/features/driver/screens/driver_home_screen.dart`
- Create: `test/unit/driver_provider_test.dart`
- Modify: `lib/core/providers/auth_provider.dart:18` (adicionar `isDriver`)
- Modify: `lib/core/widgets/auth_gate.dart` (rotear DRIVER)
- Modify: `pubspec.yaml` (adicionar `mocktail` em dev_dependencies)

**Interfaces:**
- Consumes: `ListService.getTodayLists() → Future<List<DailyList>>` (existente); `DailyList{ id, routeId, routeName, date, status, totalEntries, isOpen }`; `AsyncValue<T>` / `AsyncLoading`/`AsyncData`/`AsyncError`; `AppException.fromError(Object) → String`.
- Produces:
  - `DriverService.sendDeparture(String listId, {String? title, String? body}) → Future<int>` (retorna `notified`).
  - `DriverProvider(ListService listService, DriverService driverService)` com: `AsyncValue<List<DailyList>> get state`, `DailyList? get selected`, `bool get sending`, `Future<void> load()`, `void select(DailyList)`, `Future<int> sendDeparture(String message)`.
  - `AuthProvider.isDriver → bool`.

- [ ] **Step 1: Adicionar `mocktail` em dev_dependencies**

Em `pubspec.yaml`, dentro de `dev_dependencies:` (depois de `flutter_test:`), adicionar:

```yaml
  mocktail: ^1.0.4
```

Run: `flutter pub get`
Expected: resolve sem conflito.

- [ ] **Step 2: Criar `DriverService`**

Create `lib/features/driver/services/driver_service.dart`:

```dart
import '../../../core/services/dio_client.dart';

class DriverService {
  final _dio = DioClient.instance;

  /// Envia a notificação de saída para os inscritos ativos da lista.
  /// Backend: POST /api/lists/{id}/notifications/departure (Gap 2 — DRIVER/ADMIN).
  /// Retorna quantos alunos foram notificados.
  Future<int> sendDeparture(String listId, {String? title, String? body}) async {
    final response = await _dio.post(
      '/api/lists/$listId/notifications/departure',
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    return response.data['data']['notified'] as int;
  }
}
```

- [ ] **Step 3: Escrever o teste do `DriverProvider` (falha primeiro)**

Create `test/unit/driver_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/driver/providers/driver_provider.dart';
import 'package:smartboarding_app/features/driver/services/driver_service.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';

class _MockListService extends Mock implements ListService {}

class _MockDriverService extends Mock implements DriverService {}

DailyList _list(String id) => DailyList(
      id: id,
      routeId: 'r1',
      routeName: 'Rota Principal',
      date: '2026-07-11',
      status: 'CLOSED',
      totalEntries: 12,
    );

void main() {
  late _MockListService listService;
  late _MockDriverService driverService;
  late DriverProvider provider;

  setUp(() {
    listService = _MockListService();
    driverService = _MockDriverService();
    provider = DriverProvider(listService, driverService);
  });

  test('load popula listas e seleciona a primeira', () async {
    when(() => listService.getTodayLists())
        .thenAnswer((_) async => [_list('a'), _list('b')]);

    await provider.load();

    expect(provider.state, isA<AsyncData<List<DailyList>>>());
    expect(provider.selected?.id, 'a');
  });

  test('sendDeparture usa a lista selecionada e retorna notified', () async {
    when(() => listService.getTodayLists())
        .thenAnswer((_) async => [_list('a')]);
    when(() => driverService.sendDeparture('a', body: 'saindo'))
        .thenAnswer((_) async => 7);
    await provider.load();

    final notified = await provider.sendDeparture('saindo');

    expect(notified, 7);
    verify(() => driverService.sendDeparture('a', body: 'saindo')).called(1);
  });

  test('sendDeparture sem seleção lança StateError', () async {
    when(() => listService.getTodayLists()).thenAnswer((_) async => []);
    await provider.load();

    expect(() => provider.sendDeparture('x'), throwsStateError);
  });
}
```

- [ ] **Step 4: Rodar o teste — deve FALHAR (provider não existe)**

Run: `flutter test test/unit/driver_provider_test.dart`
Expected: FAIL — erro de compilação "Target of URI doesn't exist: '.../driver_provider.dart'".

- [ ] **Step 5: Implementar `DriverProvider`**

Create `lib/features/driver/providers/driver_provider.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/services/list_service.dart';
import '../services/driver_service.dart';

class DriverProvider extends ChangeNotifier {
  final ListService _listService;
  final DriverService _driverService;

  DriverProvider(this._listService, this._driverService);

  AsyncValue<List<DailyList>> _state = const AsyncLoading();
  AsyncValue<List<DailyList>> get state => _state;

  DailyList? _selected;
  DailyList? get selected => _selected;

  bool _sending = false;
  bool get sending => _sending;

  Future<void> load() async {
    _state = const AsyncLoading();
    _selected = null;
    notifyListeners();
    try {
      final lists = await _listService.getTodayLists();
      _state = AsyncData(lists);
      _selected = lists.isNotEmpty ? lists.first : null;
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  void select(DailyList list) {
    _selected = list;
    notifyListeners();
  }

  /// Envia a notificação de saída para a lista selecionada.
  /// Retorna quantos foram notificados. Lança em caso de erro.
  Future<int> sendDeparture(String message) async {
    final list = _selected;
    if (list == null) {
      throw StateError('Nenhuma lista selecionada');
    }
    _sending = true;
    notifyListeners();
    try {
      return await _driverService.sendDeparture(list.id, body: message);
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 6: Rodar o teste — deve PASSAR**

Run: `flutter test test/unit/driver_provider_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 7: Criar a `DriverHomeScreen`**

Create `lib/features/driver/screens/driver_home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/async_value.dart';
import '../../../core/widgets/async_builder.dart';
import '../../lists/models/daily_list_model.dart';
import '../../lists/services/list_service.dart';
import '../providers/driver_provider.dart';
import '../services/driver_service.dart';

const _defaultMessage =
    'O ônibus está saindo da rodoviária, embarque em instantes!';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DriverProvider(ListService(), DriverService())..load(),
      child: const _DriverShell(),
    );
  }
}

class _DriverShell extends StatelessWidget {
  const _DriverShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motorista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (lists) => lists.isEmpty
              ? const _EmptyState()
              : _DepartureForm(provider: provider, lists: lists),
        ),
      ),
    );
  }
}

class _DepartureForm extends StatefulWidget {
  final DriverProvider provider;
  final List<DailyList> lists;
  const _DepartureForm({required this.provider, required this.lists});

  @override
  State<_DepartureForm> createState() => _DepartureFormState();
}

class _DepartureFormState extends State<_DepartureForm> {
  final _messageCtrl = TextEditingController(text: _defaultMessage);

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final selected = widget.provider.selected;
    if (selected == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar envio'),
        content: Text(
          'Enviar a notificação de saída para os inscritos ativos da rota '
          '"${selected.routeName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final notified = await widget.provider.sendDeparture(_messageCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notificação enviada para $notified aluno(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao enviar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final selected = provider.selected;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<DailyList>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Lista / Rota do dia'),
          items: widget.lists
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text('${l.routeName} · ${l.totalEntries} inscrito(s)'),
                  ))
              .toList(),
          onChanged: (l) => l == null ? null : provider.select(l),
        ),
        const SizedBox(height: 16),
        if (selected != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text('${selected.totalEntries} inscrito(s) ativo(s)'),
              subtitle: Text('Rota: ${selected.routeName} · ${selected.date}'),
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Mensagem',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: provider.sending ? null : _confirmAndSend,
          icon: provider.sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Enviar notificação de saída'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Nenhuma lista disponível hoje'),
          ],
        ),
      );
}
```

- [ ] **Step 8: Adicionar `isDriver` no `AuthProvider`**

Em `lib/core/providers/auth_provider.dart`, depois da linha `bool get isStudent => _token?.role == 'STUDENT';` (linha ~18), adicionar:

```dart
  bool get isDriver => _token?.role == 'DRIVER';
```

- [ ] **Step 9: Rotear DRIVER no `AuthGate`**

Em `lib/core/widgets/auth_gate.dart`, adicionar o import no topo (junto aos outros):

```dart
import '../../features/driver/screens/driver_home_screen.dart';
```

E no `case AuthStatus.authenticated:` trocar:

```dart
          case AuthStatus.authenticated:
            if (auth.isAdmin) return const AdminHomeScreen();
            return const StudentHomeScreen();
```

por:

```dart
          case AuthStatus.authenticated:
            if (auth.isAdmin) return const AdminHomeScreen();
            if (auth.isDriver) return const DriverHomeScreen();
            return const StudentHomeScreen();
```

- [ ] **Step 10: Rodar analyze + todos os testes**

Run: `flutter analyze` e `flutter test`
Expected: analyze sem novos erros; testes do driver passam.

- [ ] **Step 11: Commit**

```bash
git add lib/features/driver lib/core/providers/auth_provider.dart lib/core/widgets/auth_gate.dart test/unit/driver_provider_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(driver): fluxo do motorista com notificação de saída e roteamento por papel"
```

---

### Task 3: Gestão de Usuários (Admin)

Deliverable: uma aba "Usuários" no Admin que lista os usuários e permite criar conta (aluno, motorista, admin) via formulário — o único caminho de cadastro (sem autocadastro).

**Files:**
- Create: `lib/features/users/models/user_model.dart`
- Create: `lib/features/users/services/user_service.dart`
- Create: `lib/features/users/providers/user_provider.dart`
- Create: `lib/features/users/screens/user_management_screen.dart`
- Create: `test/unit/user_provider_test.dart`
- Modify: `lib/features/home/admin_home_screen.dart` (adicionar provider, tab e destino de navegação)

**Interfaces:**
- Consumes: `DioClient.instance`; `AsyncValue<T>`; `AppException.fromError`.
- Produces:
  - `UserModel{ String id, fullName, email, role }` + `UserModel.fromJson`.
  - `UserService.getUsers() → Future<List<UserModel>>`; `UserService.register({required String fullName, required String email, required String password, required String role}) → Future<void>`.
  - `UserProvider(UserService)` com: `AsyncValue<List<UserModel>> get state`, `Future<void> load()`, `Future<void> create({required String fullName, required String email, required String password, required String role})`.

- [ ] **Step 1: Criar `UserModel`**

Create `lib/features/users/models/user_model.dart`:

```dart
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
```

- [ ] **Step 2: Criar `UserService`**

Create `lib/features/users/services/user_service.dart`:

```dart
import '../../../core/services/dio_client.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = DioClient.instance;

  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get('/api/users');
    final List data = response.data['data'] as List;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cria um usuário (ADMIN-only). Backend: POST /api/auth/register.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    await _dio.post('/api/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
    });
  }
}
```

- [ ] **Step 3: Escrever o teste do `UserProvider` (falha primeiro)**

Create `test/unit/user_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/users/models/user_model.dart';
import 'package:smartboarding_app/features/users/providers/user_provider.dart';
import 'package:smartboarding_app/features/users/services/user_service.dart';

class _MockUserService extends Mock implements UserService {}

void main() {
  late _MockUserService service;
  late UserProvider provider;

  setUp(() {
    service = _MockUserService();
    provider = UserProvider(service);
  });

  test('load popula a lista de usuários', () async {
    when(() => service.getUsers()).thenAnswer((_) async => const [
          UserModel(id: '1', fullName: 'Ana', email: 'a@x.com', role: 'STUDENT'),
        ]);

    await provider.load();

    expect(provider.state, isA<AsyncData<List<UserModel>>>());
    final data = provider.state as AsyncData<List<UserModel>>;
    expect(data.value.single.fullName, 'Ana');
  });

  test('create chama register e recarrega a lista', () async {
    when(() => service.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          role: any(named: 'role'),
        )).thenAnswer((_) async {});
    when(() => service.getUsers()).thenAnswer((_) async => const []);

    await provider.create(
      fullName: 'João',
      email: 'j@x.com',
      password: '123456',
      role: 'DRIVER',
    );

    verify(() => service.register(
          fullName: 'João',
          email: 'j@x.com',
          password: '123456',
          role: 'DRIVER',
        )).called(1);
    verify(() => service.getUsers()).called(1);
  });
}
```

- [ ] **Step 4: Rodar o teste — deve FALHAR (provider não existe)**

Run: `flutter test test/unit/user_provider_test.dart`
Expected: FAIL — "Target of URI doesn't exist: '.../user_provider.dart'".

- [ ] **Step 5: Implementar `UserProvider`**

Create `lib/features/users/providers/user_provider.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service;

  AsyncValue<List<UserModel>> _state = const AsyncLoading();
  AsyncValue<List<UserModel>> get state => _state;

  UserProvider(this._service);

  Future<void> load() async {
    _state = const AsyncLoading();
    notifyListeners();
    try {
      _state = AsyncData(await _service.getUsers());
    } catch (e) {
      _state = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  /// Cria um usuário e recarrega a lista. Lança exceção em caso de erro.
  Future<void> create({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    await _service.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
    await load();
  }
}
```

- [ ] **Step 6: Rodar o teste — deve PASSAR**

Run: `flutter test test/unit/user_provider_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 7: Criar a `UserManagementScreen`**

Create `lib/features/users/screens/user_management_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/async_builder.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

const _roles = ['STUDENT', 'DRIVER', 'ADMIN'];
const _roleLabels = {
  'STUDENT': 'Aluno',
  'DRIVER': 'Motorista',
  'ADMIN': 'Admin',
};

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, provider, _) => AsyncBuilder(
          value: provider.state,
          onRetry: provider.load,
          builder: (users) => users.isEmpty
              ? const Center(child: Text('Nenhum usuário cadastrado'))
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserTile(user: users[i]),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo usuário'),
      ),
    );
  }

  void _openCreateForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<UserProvider>(),
        child: const _CreateUserForm(),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(user.fullName.characters.first)),
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: Chip(label: Text(_roleLabels[user.role] ?? user.role)),
      ),
    );
  }
}

class _CreateUserForm extends StatefulWidget {
  const _CreateUserForm();

  @override
  State<_CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<_CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'STUDENT';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<UserProvider>().create(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            role: _role,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao criar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Novo usuário',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mínimo 6 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Papel'),
              items: _roles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabels[r]!),
                      ))
                  .toList(),
              onChanged: (r) => setState(() => _role = r ?? 'STUDENT'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar usuário'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Wire no `AdminHomeScreen` — provider, tab e destino**

Em `lib/features/home/admin_home_screen.dart`:

a) Adicionar imports (junto aos outros no topo):

```dart
import '../users/providers/user_provider.dart';
import '../users/screens/user_management_screen.dart';
import '../users/services/user_service.dart';
```

b) No `MultiProvider` (dentro de `AdminHomeScreen.build`), adicionar ao final da lista `providers:`:

```dart
        ChangeNotifierProvider(
            create: (_) => UserProvider(UserService())..load()),
```

c) No `IndexedStack.children` do `_AdminShell`, adicionar `UserManagementScreen()` ao final:

```dart
        children: const [
          _AdminListsTab(),
          RoutesScreen(),
          ReportsScreen(),
          BroadcastScreen(),
          UserManagementScreen(),
        ],
```

d) No `NavigationBar.destinations`, adicionar ao final:

```dart
          NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Usuários'),
```

- [ ] **Step 9: Rodar analyze + todos os testes**

Run: `flutter analyze` e `flutter test`
Expected: analyze sem novos erros; todos os testes passam.

- [ ] **Step 10: Commit**

```bash
git add lib/features/users lib/features/home/admin_home_screen.dart test/unit/user_provider_test.dart
git commit -m "feat(users): gestão de usuários no admin com criação de conta por papel"
```

---

### Task 4: Preparo de Push (Firebase) — documentação + pontos de integração

Deliverable: um guia de ativação do Firebase e os pontos de integração marcados no código, sem adicionar dependências que quebrem o build (decisão: "estruturado, ativar depois"). Nenhuma dependência Firebase entra no `pubspec.yaml` ainda — isso é feito quando o usuário rodar `flutterfire configure` (documentado no guia).

**Files:**
- Create: `docs/firebase-setup.md`
- Modify: `lib/core/providers/auth_provider.dart` (comentários TODO nos pontos de registro/remoção de token)

**Interfaces:**
- Consumes: `NotificationService.registerToken(String token, String platform)` e `removeToken()` (já existentes em `lib/features/notifications/services/notification_service.dart`).
- Produces: nenhuma API nova — apenas documentação e marcadores.

- [ ] **Step 1: Escrever o guia de ativação**

Create `docs/firebase-setup.md`:

```markdown
# Ativação do Firebase / Push (FCM)

Status: **código do app pronto para receber; Firebase ainda NÃO ativado.**
O app compila e roda sem Firebase. Este guia liga o push quando você estiver pronto.

## Passo a passo

1. Garantir as plataformas: `flutter create . --platforms=android,ios`
   (as pastas `android/` e `ios/` já existem — este comando é idempotente).
2. Criar o projeto no [Firebase Console](https://console.firebase.google.com).
3. `dart pub global activate flutterfire_cli` e depois `flutterfire configure`.
   Isso registra os apps Android/iOS, baixa `google-services.json` /
   `GoogleService-Info.plist` e gera `lib/firebase_options.dart`.
4. Ativar a **Cloud Messaging API** no projeto Firebase.
5. Adicionar as dependências no `pubspec.yaml` e rodar `flutter pub get`:
   ```yaml
   firebase_core: ^3.6.0
   firebase_messaging: ^15.1.3
   flutter_local_notifications: ^18.0.1
   ```
6. Em `lib/main.dart`, inicializar antes do `runApp`:
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
7. Após login, registrar o token (ver TODO em `auth_provider.dart`):
   ```dart
   final messaging = FirebaseMessaging.instance;
   await messaging.requestPermission();
   final token = await messaging.getToken();
   if (token != null) {
     await NotificationService().registerToken(token, Platform.isIOS ? 'ios' : 'android');
   }
   ```
8. No logout, remover o token: `await NotificationService().removeToken();`
   (ver TODO em `auth_provider.dart`).
9. Foreground: `FirebaseMessaging.onMessage.listen(...)` exibindo via
   `flutter_local_notifications`. Background: `FirebaseMessaging.onBackgroundMessage(...)`.
10. Validar com um envio de teste pelo Firebase Console antes de integrar
    com o backend.

## Backend
- Gerar a Service Account JSON (Firebase Console → Configurações → Contas de
  serviço) e apontar `FIREBASE_CREDENTIALS_PATH` no `.env` do `smartboarding-api`.

## Contrato já usado pelo app (não muda)
- `POST /api/devices/token { token, platform }` — `NotificationService.registerToken`
- `DELETE /api/devices/token` — `NotificationService.removeToken`
```

- [ ] **Step 2: Marcar os pontos de integração no `AuthProvider`**

Em `lib/core/providers/auth_provider.dart`, dentro de `login`, após `_status = AuthStatus.authenticated;` e antes de `notifyListeners();`, adicionar:

```dart
    // TODO(firebase): registrar device token FCM aqui após ativar o push.
    // Ver docs/firebase-setup.md, passo 7 (NotificationService().registerToken).
```

E dentro de `logout`, após `await _authService.logout();`, adicionar:

```dart
    // TODO(firebase): remover device token FCM aqui após ativar o push.
    // Ver docs/firebase-setup.md, passo 8 (NotificationService().removeToken).
```

- [ ] **Step 3: Verificar analyze**

Run: `flutter analyze`
Expected: sem novos erros.

- [ ] **Step 4: Commit**

```bash
git add docs/firebase-setup.md lib/core/providers/auth_provider.dart
git commit -m "docs(push): guia de ativação do Firebase e pontos de integração de token"
```

---

### Task 5: Limpeza de lint + verificação final

Deliverable: `flutter analyze` limpo (0 issues) e suíte de testes verde.

**Files:**
- Modify: `lib/features/home/admin_home_screen.dart:119` (`(_, __)` → `(_, _)`)
- Modify: `lib/features/reports/screens/reports_screen.dart:29`
- Modify: `lib/features/routes/screens/routes_screen.dart:30`

**Interfaces:** nenhuma mudança de API.

- [ ] **Step 1: Corrigir os `unnecessary_underscores`**

Em cada arquivo, trocar o separador do `ListView.separated` de `separatorBuilder: (_, __) =>` para `separatorBuilder: (_, _) =>`:
- `lib/features/home/admin_home_screen.dart` (linha ~119)
- `lib/features/reports/screens/reports_screen.dart` (linha ~29)
- `lib/features/routes/screens/routes_screen.dart` (linha ~30)

(Localizar cada ocorrência com `grep -n "(_, __)"` nesses arquivos antes de editar, pois o número da linha pode ter mudado.)

- [ ] **Step 2: Analyze deve estar limpo**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 3: Rodar toda a suíte de testes**

Run: `flutter test`
Expected: todos passam (driver + user providers).

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/admin_home_screen.dart lib/features/reports/screens/reports_screen.dart lib/features/routes/screens/routes_screen.dart
git commit -m "chore: corrige lints unnecessary_underscores"
```

- [ ] **Step 5: Verificação manual (opcional, recomendado)**

Com o backend rodando, `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` no emulador Android:
- Login como ADMIN → ver a aba "Usuários", criar um usuário.
- Login como STUDENT → tela do aluno.
- (Motorista fica bloqueado no envio real até os Gaps 1/2 do backend, mas a tela é navegável se houver um usuário DRIVER.)

---

## Notas de cobertura da spec

- **Tema verde light+dark** (spec §4.5) → Task 1.
- **Fluxo do motorista** (spec §5.2) → Task 2 (UI completa; envio real depende do Gap 2 do backend, documentado).
- **Role DRIVER no roteamento e no cadastro** (spec §2, §5.3) → Task 2 (roteamento) + Task 3 (opção no formulário).
- **Gestão de usuários / cadastro por ADMIN** (spec §5.3) → Task 3.
- **Push/FCM estruturado** (spec §6, decisão de 2026-07-11) → Task 4.
- **Qualidade** (spec §11 fase 6) → Task 5.

## Fora do escopo deste plano (documentado para não esquecer)
- Ativação real do Firebase (`flutterfire configure`, deps, handlers) — passo interativo do usuário, guiado por `docs/firebase-setup.md`.
- Backend Gaps 1/2/3 (role DRIVER no enum, endpoint de departure, broadcast automático de abertura) — fora desta fase (spec §8).
- Migração para openapi-generator — descartada nesta fase (spec §0, decisão revisada).
