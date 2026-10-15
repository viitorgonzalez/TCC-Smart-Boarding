import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/core/widgets/app_card.dart';
import 'package:smartboarding_app/features/home/student_home_screen.dart';
import 'package:smartboarding_app/features/lists/providers/student_list_provider.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';
import 'package:smartboarding_app/features/membership/providers/membership_provider.dart';
import 'package:smartboarding_app/features/profile/providers/me_provider.dart';

import '../support/fake_http.dart';

Future<void> abrirHome(WidgetTester tester, {bool comLista = true}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on(
    'GET',
    '/api/me/routes',
    body: {
      'data': [
        {
          'id': 'rota-1',
          'name': 'Rota Universitária de Formiga',
          'isActive': true,
          'openTime': '05:00:00',
          'closeTime': '16:00:00',
          'createdAt': '2026-08-14T18:25:58',
        },
      ],
    },
  );
  http.on(
    'GET',
    '/api/lists/today',
    body: {
      'data': comLista
          ? [
              {
                'id': 'l1',
                'routeId': 'rota-1',
                'routeName': 'Rota Universitária de Formiga',
                'date': '2026-10-14',
                'status': 'CLOSED',
                'totalEntries': 7,
                'enrolled': true,
                'closeTime': '19:00:00',
              },
            ]
          : [],
    },
  );
  http.always(body: {'data': []});

  final membership = MembershipProvider();
  await tester.runAsync(membership.load);
  final lists = StudentListProvider(ListService());
  // O provider só busca depois de saber de quem é a sessão.
  lists.setUserEmail('fernanda@edu.unifor.br');
  await tester.runAsync(lists.load);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider.value(value: membership),
        ChangeNotifierProvider.value(value: lists),
        ChangeNotifierProvider(create: (_) => MeProvider()),
      ],
      child: const MaterialApp(home: StudentHomeScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

AppCard bannerDeHoje(WidgetTester tester) =>
    tester.widget<AppCard>(find.byKey(const Key('student_today_status')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('o avatar é o atalho do perfil', (tester) async {
    await abrirHome(tester);

    final avatar = find.byKey(const Key('student_open_profile'));
    expect(avatar, findsOneWidget);
    expect(tester.widget<InkWell>(avatar).onTap, isNotNull);
  });

  testWidgets('o menu não oferece mais "Meu perfil", só sair', (tester) async {
    await abrirHome(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Meu perfil'), findsNothing);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('com lista do dia, o banner abre a lista', (tester) async {
    await abrirHome(tester);

    expect(bannerDeHoje(tester).onTap, isNotNull);
  });

  testWidgets('sem lista do dia, o banner não leva a lugar nenhum', (
    tester,
  ) async {
    await abrirHome(tester, comLista: false);

    expect(bannerDeHoje(tester).onTap, isNull);
  });

  testWidgets('lista fechada continua acessível pelo banner', (tester) async {
    await abrirHome(tester);

    expect(find.text('Lista fechada'), findsNothing);
    expect(find.text('Você está na lista'), findsOneWidget);
    expect(bannerDeHoje(tester).onTap, isNotNull);
  });
}
