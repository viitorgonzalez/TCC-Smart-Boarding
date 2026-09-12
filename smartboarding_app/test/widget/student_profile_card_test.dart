import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/users/models/student_profile_model.dart';
import 'package:smartboarding_app/features/users/widgets/student_profile_card.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final perfil = StudentProfile(
    id: 'aluno-1',
    fullName: 'Ana Oliveira',
    email: 'ana@edu.unifor.br',
    phone: '37999990000',
    address: 'Rua das Flores, 45',
    birthDate: '2004-03-12',
    course: 'Ciência da Computação',
    institution: 'UNIFOR-MG',
    isActive: false,
    role: 'STUDENT',
    recentAttendance: const ['2026-09-01', '2026-09-02'],
    statusHistory: const [
      StatusChange(
        action: 'DEACTIVATED',
        adminName: 'System Administrator',
        at: '2026-09-08T14:00:00',
      ),
    ],
  );

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  // Decisao invertida em 09/09/2026 a pedido do autor: a ficha passou a carregar
  // contato porque o admin precisa falar com o aluno. Senha continua fora -- ela
  // nao tem uso de leitura nenhum.
  testWidgets('card mostra contato, mas nunca senha', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('@'), findsWidgets);
    expect(find.textContaining('Rua'), findsOneWidget);
    expect(find.textContaining(r'$2a$'), findsNothing);
    expect(find.textContaining('senha'), findsNothing);
  });

  testWidgets('card mostra quem mudou o status e quando', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Desativado por System Administrator'),
      findsOneWidget,
    );
  });

  testWidgets('alternar o switch avisa quem abriu o card', (tester) async {
    bool? recebido;
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (v) => recebido = v,
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(recebido, isTrue);
  });

  testWidgets('conta inativa aparece como inativa', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inativo'), findsOneWidget);
  });

  testWidgets('ficha mostra contato e nascimento formatado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentProfileBody(
            profile: perfil,
            onToggle: (_) {},
            onToggleRole: () {},
            ehAPropriaConta: false,
            ehUltimoAdmin: false,
          ),
        ),
      ),
    );

    expect(find.text('ana@edu.unifor.br'), findsOneWidget);
    expect(find.text('37999990000'), findsOneWidget);
    expect(find.text('Rua das Flores, 45'), findsOneWidget);
    expect(find.text('12/03/2004'), findsOneWidget);
  });

  // Campo vazio some em vez de virar rotulo com travessao: linha em branco so
  // ocupa espaco e nao informa nada.
  testWidgets('campo ausente nao vira linha vazia', (tester) async {
    final semContato = StudentProfile(
      id: 'aluno-2',
      fullName: 'Bruno Silva',
      isActive: true,
      role: 'STUDENT',
      email: 'bruno@edu.unifor.br',
      phone: '   ',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentProfileBody(
            profile: semContato,
            onToggle: (_) {},
            onToggleRole: () {},
            ehAPropriaConta: false,
            ehUltimoAdmin: false,
          ),
        ),
      ),
    );

    expect(find.text('bruno@edu.unifor.br'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(find.byIcon(Icons.cake_outlined), findsNothing);
  });

  StudentProfile comPapel(String role, {bool ativa = true}) => StudentProfile(
    id: perfil.id,
    fullName: perfil.fullName,
    email: perfil.email,
    phone: perfil.phone,
    address: perfil.address,
    birthDate: perfil.birthDate,
    course: perfil.course,
    institution: perfil.institution,
    isActive: ativa,
    role: role,
    recentAttendance: perfil.recentAttendance,
    statusHistory: perfil.statusHistory,
  );

  /// A trava aparece como ausencia de opcao, nao como erro depois do toque: o
  /// admin nao descobre que nao podia so quando a API recusa.
  testWidgets('a propria conta nao oferece troca de papel', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('ADMIN'),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: true,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_role_action')), findsNothing);
  });

  testWidgets('conta de aluno oferece promover', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('STUDENT'),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_role_action')), findsOneWidget);
    expect(find.text('Tornar administrador'), findsOneWidget);
  });

  /// Promover conta desativada produz um admin que nao consegue entrar.
  testWidgets('conta desativada nao oferece promover', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('STUDENT', ativa: false),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isFalse);
  });

  /// Ultimo admin ativo: rebaixar travaria o sistema por fora -- ninguem mais
  /// promove ninguem de volta. Mesmo tratamento da conta desativada: some a
  /// opcao de tocar, nao o erro depois do toque.
  testWidgets('ultimo admin nao pode ser rebaixado', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('ADMIN'),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isFalse);
  });

  testWidgets('admin com outro admin na lista pode ser rebaixado', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('ADMIN'),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isTrue);
  });

  // ─── StudentProfileSheet: a trava do ultimo admin de ponta a ponta ──────
  //
  // Os testes acima provam só a relação flag→enabled em StudentProfileBody,
  // que é apresentação. Quem calcula ehUltimoAdmin a partir da contagem real
  // (e implementa o fail-open) é StudentProfileSheetState -- então é ela que
  // precisa estar sob teste aqui, com a camada HTTP falsa.

  /// Monta a ficha de verdade (não o Body) com GET /api/users/{id}/profile e
  /// GET /api/users/admins/count stubados. [admins] é a contagem devolvida;
  /// [status] deixa simular a rota falhando (ex.: 500) pro cenário de fail-open.
  Future<FakeHttpAdapter> abrirFicha(
    WidgetTester tester, {
    required int admins,
    int status = 200,
  }) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on(
      'GET',
      '/api/users/admin-1/profile',
      body: {
        'data': {
          'id': 'admin-1',
          'fullName': 'Admin Um',
          'email': 'admin1@edu.unifor.br',
          'isActive': true,
          'role': 'ADMIN',
          'recentAttendance': [],
          'statusHistory': [],
        },
      },
    );
    http.on(
      'GET',
      '/api/users/admins/count',
      status: status,
      body: {'data': {'count': admins}},
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(
          home: Scaffold(body: StudentProfileSheet(userId: 'admin-1')),
        ),
      ),
    );
    // Espera pela condicao (a ficha terminar as duas buscas do initState), nao
    // por uma duracao chutada: StudentProfileSheetState.carregado so existe
    // pra isso. Um unico "await tester.runAsync(() => state.carregado)" trava
    // pra sempre -- as buscas comecam dentro do initState, sob o relogio
    // falso do testWidgets, entao parte da cadeia so anda com o relogio falso
    // avancando (pump) e parte só com tempo real (runAsync); nenhum dos dois
    // sozinho é suficiente. O laco intercala as duas coisas e para assim que
    // "carregado" resolver, com um teto pra nao travar se quebrar de verdade.
    final state = tester.state<StudentProfileSheetState>(
      find.byType(StudentProfileSheet),
    );
    var pronto = false;
    state.carregado.then((_) => pronto = true);
    const maxTentativas = 200;
    var tentativas = 0;
    while (!pronto && tentativas < maxTentativas) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 1));
      tentativas++;
    }
    if (!pronto) {
      fail(
        'StudentProfileSheetState.carregado nao resolveu apos $maxTentativas '
        'tentativas -- a ficha nao carregou.',
      );
    }
    // Mais um pump sem duracao: garante que o ultimo setState (o que marcou
    // "pronto") já virou frame construído antes da asserção.
    await tester.pump();

    return http;
  }

  testWidgets('um admin so: rebaixar fica desabilitado', (tester) async {
    await abrirFicha(tester, admins: 1);

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isFalse);
  });

  testWidgets('dois admins: rebaixar fica habilitado', (tester) async {
    await abrirFicha(tester, admins: 2);

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isTrue);
  });

  /// Fail-open: se a contagem nem chega, a tela não pode travar por engano --
  /// quem recusa de verdade é o backend, no toque.
  testWidgets('a contagem de admins falha: rebaixar continua habilitado', (
    tester,
  ) async {
    await abrirFicha(tester, admins: 0, status: 500);

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isTrue);
  });

  /// A folha abre de três telas e busca de novo a cada promoção. Baixar
  /// `/api/users` pra contar levaria e-mail, telefone, endereço e nascimento da
  /// base inteira no fio — payload sem teto pra chegar num número.
  testWidgets('a ficha nunca baixa a tabela de usuários pra contar admins', (
    tester,
  ) async {
    final http = await abrirFicha(tester, admins: 2);

    expect(
      http.requests.map((r) => r.path),
      isNot(contains('/api/users')),
    );
    expect(
      http.requests.map((r) => r.path),
      contains('/api/users/admins/count'),
    );
  });

}
