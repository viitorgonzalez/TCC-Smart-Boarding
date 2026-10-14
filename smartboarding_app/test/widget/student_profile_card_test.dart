import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/users/models/student_profile_model.dart';
import 'package:smartboarding_app/features/users/widgets/student_profile_card.dart';

import '../support/fake_http.dart';
import '../support/pump_until.dart';

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

  testWidgets('admin ativo nao pode ser desativado pela ficha', (tester) async {
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

    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const Key('profile_active_switch')),
    );
    expect(switchTile.onChanged, isNull);
    expect(
      find.text('Remova o acesso de administrador antes de desativar.'),
      findsOneWidget,
    );
  });

  testWidgets('admin inativo ainda pode ser reativado', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('ADMIN', ativa: false),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
          ehUltimoAdmin: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const Key('profile_active_switch')),
    );
    expect(switchTile.onChanged, isNotNull);
  });

  testWidgets('aluno ativo segue podendo ser desativado', (tester) async {
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

    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const Key('profile_active_switch')),
    );
    expect(switchTile.onChanged, isNotNull);
    expect(
      find.text('A mudança fica registrada com seu nome e a hora.'),
      findsOneWidget,
    );
  });

  Future<FakeHttpAdapter> abrirFicha(
    WidgetTester tester, {
    required int admins,
    int status = 200,
    VoidCallback? onChanged,
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
      body: {
        'data': {'count': admins},
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: StudentProfileSheet(userId: 'admin-1', onChanged: onChanged),
          ),
        ),
      ),
    );
    final state = tester.state<StudentProfileSheetState>(
      find.byType(StudentProfileSheet),
    );
    var pronto = false;
    state.carregado.then((_) => pronto = true);
    await pumpUntil(
      tester,
      () => pronto,
      describe: 'a ficha terminar as buscas do initState',
    );

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

  testWidgets('a contagem de admins falha: rebaixar continua habilitado', (
    tester,
  ) async {
    await abrirFicha(tester, admins: 0, status: 500);

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isTrue);
  });

  testWidgets('a ficha nunca baixa a tabela de usuários pra contar admins', (
    tester,
  ) async {
    final http = await abrirFicha(tester, admins: 2);

    expect(http.requests.map((r) => r.path), isNot(contains('/api/users')));
    expect(
      http.requests.map((r) => r.path),
      contains('/api/users/admins/count'),
    );
  });

  testWidgets('mudar o papel avisa quem abriu a folha', (tester) async {
    var avisou = false;
    final http = await abrirFicha(
      tester,
      admins: 2,
      onChanged: () => avisou = true,
    );
    http.on(
      'PATCH',
      '/api/users/admin-1/role',
      body: {
        'data': {
          'id': 'admin-1',
          'fullName': 'Admin Um',
          'email': 'admin1@edu.unifor.br',
          'isActive': true,
          'role': 'STUDENT',
          'recentAttendance': [],
          'statusHistory': [],
        },
      },
    );

    await tester.tap(find.byKey(const Key('profile_role_action')));
    await pumpUntil(
      tester,
      () => avisou,
      describe: 'o aviso de mudança de papel',
    );

    expect(avisou, isTrue);
  });

  testWidgets('papel recusado pelo backend não avisa mudança', (tester) async {
    var avisou = false;
    final http = await abrirFicha(
      tester,
      admins: 2,
      onChanged: () => avisou = true,
    );
    http.on(
      'PATCH',
      '/api/users/admin-1/role',
      status: 400,
      body: {
        'error': {
          'code': 'LAST_ADMIN',
          'message': 'Este é o único administrador.',
        },
      },
    );

    await tester.tap(find.byKey(const Key('profile_role_action')));
    await pumpUntil(
      tester,
      () => http.requests.any((r) => r.method == 'PATCH'),
      describe: 'o PATCH de papel',
    );

    expect(avisou, isFalse);
  });

  testWidgets('a folha nao fecha enquanto grava', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('STUDENT'),
          busy: true,
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
    expect(tile.enabled, isFalse, reason: 'ocupado desabilita a acao');
  });
}
