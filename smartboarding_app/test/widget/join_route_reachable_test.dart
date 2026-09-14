import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/home/student_home_screen.dart';
import 'package:smartboarding_app/features/lists/providers/student_list_provider.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';
import 'package:smartboarding_app/features/membership/providers/membership_provider.dart';
import 'package:smartboarding_app/features/membership/screens/join_route_screen.dart';

import '../support/fake_http.dart';

/// [rotas] e quantas rotas o aluno ja tem -- e o que decidia se a porta pro
/// codigo aparecia ou nao.
Future<void> abrirHome(WidgetTester tester, {required int rotas}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on(
    'GET',
    '/api/me/routes',
    body: {
      'data': List.generate(
        rotas,
        (i) => {
          'id': 'rota-$i',
          'name': 'Rota $i',
          'isActive': true,
          'openTime': '05:00:00',
          'closeTime': '16:00:00',
          'createdAt': '2026-08-14T18:25:58',
        },
      ),
    },
  );
  http.always(body: {'data': []});

  // runAsync: dentro de testWidgets o relogio e falso, e o Dio pendura o
  // request nos timers de connect/receive -- o await nunca voltaria.
  final membership = MembershipProvider();
  await tester.runAsync(membership.load);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider.value(value: membership),
        ChangeNotifierProvider(
          create: (_) => StudentListProvider(ListService()),
        ),
      ],
      child: const MaterialApp(home: StudentHomeScreen()),
    ),
  );
  // pump fixo em vez de pumpAndSettle: o status do dia mostra um
  // CircularProgressIndicator, que anima pra sempre e nunca deixa a arvore
  // assentar.
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// O caso que estava quebrado: com UMA rota, o NoRouteCard nao aparece (ele e
  /// so do estado vazio) e o chip "Outra rota" tambem nao (ele pede duas ou
  /// mais). O aluno ficava sem nenhuma porta pro codigo.
  testWidgets('com uma rota ainda da pra entrar em outra', (tester) async {
    await abrirHome(tester, rotas: 1);

    await tester.tap(find.byKey(const Key('student_home_join_route')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(JoinRouteScreen), findsOneWidget);
  });

  testWidgets('sem rota nenhuma tambem chega na tela do codigo', (
    tester,
  ) async {
    await abrirHome(tester, rotas: 0);

    await tester.tap(find.byKey(const Key('student_home_join_route')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(JoinRouteScreen), findsOneWidget);
  });

  testWidgets('com varias rotas a porta continua no lugar', (tester) async {
    await abrirHome(tester, rotas: 3);

    expect(find.byKey(const Key('student_home_join_route')), findsOneWidget);
  });
}
