import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/features/home/my_routes_screen.dart';
import 'package:smartboarding_app/features/membership/providers/membership_provider.dart';
import 'package:smartboarding_app/features/membership/screens/join_route_screen.dart';

import '../support/fake_http.dart';

Future<void> abrir(WidgetTester tester, {required int rotas}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on(
    'GET',
    '/api/me/routes',
    body: {
      'data': List.generate(
        rotas,
        (i) => {
          'id': 'rota-$i',
          'name': 'Rota ${i + 1}',
          'isActive': true,
          'openTime': '05:00:00',
          'closeTime': '16:00:00',
          'createdAt': '2026-08-14T18:25:58',
        },
      ),
    },
  );
  http.always(body: {'data': []});

  final membership = MembershipProvider();
  await tester.runAsync(membership.load);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: membership,
      child: const MaterialApp(home: MyRoutesScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lista as rotas do aluno', (tester) async {
    await abrir(tester, rotas: 2);

    expect(find.text('Rota 1'), findsOneWidget);
    expect(find.text('Rota 2'), findsOneWidget);
  });

  /// O gesto do Classroom: a porta pro codigo mora junto das turmas, nao
  /// escondida noutro canto.
  testWidgets('entrar com codigo fica nesta tela', (tester) async {
    await abrir(tester, rotas: 1);

    await tester.tap(find.byKey(const Key('my_routes_join')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(JoinRouteScreen), findsOneWidget);
  });

  /// Sem rota nenhuma a tela nao pode ficar muda: e exatamente quando o aluno
  /// precisa saber que existe um codigo e que ele vem do administrador.
  testWidgets('sem rota, explica como entrar', (tester) async {
    await abrir(tester, rotas: 0);

    expect(find.byKey(const Key('my_routes_join')), findsOneWidget);
    expect(find.textContaining('código'), findsWidgets);
  });
}
