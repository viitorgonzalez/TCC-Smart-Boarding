import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/routes/models/route_model.dart';
import 'package:smartboarding_app/features/routes/screens/invite_codes_screen.dart';

import '../support/fake_http.dart';
import '../support/pump_until.dart';

RouteModel rota(String id, String nome) => RouteModel(
  id: id,
  name: nome,
  isActive: true,
  createdAt: '2026-01-01T00:00:00',
);

Map<String, dynamic> codigo({
  String id = 'c1',
  String code = 'ABC123',
  String rota = 'Rota Universitária de Formiga',
  String routeId = 'r1',
  bool usable = true,
  int uses = 0,
  String? institutionName,
}) => {
  'id': id,
  'routeId': routeId,
  'routeName': rota,
  'code': code,
  'expiresAt': '2026-12-31T23:59:59',
  'revokedAt': null,
  'usable': usable,
  'uses': uses,
  'institutionId': institutionName == null ? null : 'i1',
  'institutionName': institutionName,
};

Future<FakeHttpAdapter> abrir(
  WidgetTester tester, {
  required List<Map<String, dynamic>> codigos,
  List<RouteModel>? rotas,
}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on('GET', '/api/invite-codes', body: {'data': codigos});
  await tester.pumpWidget(
    MaterialApp(
      home: InviteCodesScreen(
        routes: rotas ?? [rota('r1', 'Rota Universitária de Formiga')],
      ),
    ),
  );
  await pumpUntil(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    describe: 'a listagem carregar',
  );
  return http;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('busca os codigos de todas as rotas numa chamada', (
    tester,
  ) async {
    final http = await abrir(tester, codigos: [codigo()]);

    expect(
      http.requests.where((r) => r.path == '/api/invite-codes'),
      hasLength(1),
    );
    expect(find.text('ABC123'), findsOneWidget);
  });

  testWidgets('agrupa por rota', (tester) async {
    await abrir(
      tester,
      codigos: [
        codigo(id: 'c1', code: 'AAA111', rota: 'Rota A', routeId: 'r1'),
        codigo(id: 'c2', code: 'BBB222', rota: 'Rota B', routeId: 'r2'),
      ],
    );

    expect(find.text('Rota A'), findsOneWidget);
    expect(find.text('Rota B'), findsOneWidget);
  });

  group('filtro por rota', () {
    testWidgets('com uma rota so, nao mostra filtro nenhum', (tester) async {
      await abrir(tester, codigos: [codigo()]);

      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('com varias rotas, filtra os codigos ao tocar no chip', (
      tester,
    ) async {
      await abrir(
        tester,
        rotas: [rota('r1', 'Rota A'), rota('r2', 'Rota B')],
        codigos: [
          codigo(id: 'c1', code: 'AAA111', rota: 'Rota A', routeId: 'r1'),
          codigo(id: 'c2', code: 'BBB222', rota: 'Rota B', routeId: 'r2'),
        ],
      );
      expect(find.text('AAA111'), findsOneWidget);
      expect(find.text('BBB222'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Rota A'));
      await tester.pumpAndSettle();

      expect(find.text('AAA111'), findsOneWidget);
      expect(find.text('BBB222'), findsNothing);
    });

    testWidgets('"Todas" volta a mostrar tudo', (tester) async {
      await abrir(
        tester,
        rotas: [rota('r1', 'Rota A'), rota('r2', 'Rota B')],
        codigos: [
          codigo(id: 'c1', code: 'AAA111', rota: 'Rota A', routeId: 'r1'),
          codigo(id: 'c2', code: 'BBB222', rota: 'Rota B', routeId: 'r2'),
        ],
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Rota A'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Todas'));
      await tester.pumpAndSettle();

      expect(find.text('AAA111'), findsOneWidget);
      expect(find.text('BBB222'), findsOneWidget);
    });
  });

  testWidgets('mostra a instituicao de cada codigo', (tester) async {
    await abrir(tester, codigos: [codigo(institutionName: 'IFMG')]);

    expect(find.textContaining('IFMG'), findsOneWidget);
  });

  testWidgets('codigo sem instituicao aparece como aberto', (tester) async {
    await abrir(tester, codigos: [codigo()]);

    expect(find.textContaining('Qualquer instituição'), findsOneWidget);
  });

  testWidgets('codigo inutilizavel nao oferece copiar nem cancelar', (
    tester,
  ) async {
    await abrir(tester, codigos: [codigo(usable: false)]);

    expect(find.byKey(const Key('copy_c1')), findsNothing);
    expect(find.byKey(const Key('revoke_c1')), findsNothing);
  });

  testWidgets('sem codigo nenhum, convida a gerar o primeiro', (tester) async {
    await abrir(tester, codigos: const []);

    expect(find.text('Nenhum código criado'), findsOneWidget);
    expect(find.byKey(const Key('generate_code_fab')), findsOneWidget);
  });

  testWidgets('com uma rota so, ainda pede confirmacao da rota', (
    tester,
  ) async {
    final http = await abrir(tester, codigos: [codigo()]);
    http.on('GET', '/api/institutions', body: {'data': []});

    await tester.tap(find.byKey(const Key('generate_code_fab')));
    await tester.pumpAndSettle();

    expect(find.text('Para qual rota?'), findsOneWidget);
    expect(find.text('Rota Universitária de Formiga'), findsWidgets);
  });

  testWidgets('escolher a rota leva pra validade', (tester) async {
    final http = await abrir(tester, codigos: [codigo()]);
    http.on('GET', '/api/institutions', body: {'data': []});

    await tester.tap(find.byKey(const Key('generate_code_fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rota Universitária de Formiga').last);
    await tester.pumpAndSettle();

    expect(find.text('Por quanto tempo o código vale?'), findsOneWidget);
  });

  testWidgets('com varias rotas, pergunta a rota primeiro', (tester) async {
    final http = await abrir(
      tester,
      codigos: [codigo()],
      rotas: [rota('r1', 'Rota A'), rota('r2', 'Rota B')],
    );
    http.on('GET', '/api/institutions', body: {'data': []});

    await tester.tap(find.byKey(const Key('generate_code_fab')));
    await tester.pumpAndSettle();

    expect(find.text('Para qual rota?'), findsOneWidget);
  });

  testWidgets('o atalho marca so os inutilizaveis', (tester) async {
    await abrir(
      tester,
      codigos: [
        codigo(id: 'vivo', code: 'VIVO11'),
        codigo(id: 'morto', code: 'MORTO1', usable: false),
      ],
    );

    await tester.tap(find.byKey(const Key('select_unusable')));
    await tester.pumpAndSettle();

    expect(find.text('1 selecionado'), findsOneWidget);
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('check_morto'))).value,
      isTrue,
    );
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('check_vivo'))).value,
      isFalse,
    );
  });

  testWidgets('sem inutilizavel, o atalho nao aparece', (tester) async {
    await abrir(tester, codigos: [codigo()]);

    expect(find.byKey(const Key('select_unusable')), findsNothing);
  });

  testWidgets('segurar entra na selecao', (tester) async {
    await abrir(tester, codigos: [codigo()]);

    await tester.longPress(find.byKey(const Key('code_c1')));
    await tester.pumpAndSettle();

    expect(find.text('1 selecionado'), findsOneWidget);
    expect(find.byKey(const Key('generate_code_fab')), findsNothing);
  });

  testWidgets('apagar manda o lote e recarrega', (tester) async {
    final http = await abrir(
      tester,
      codigos: [
        codigo(id: 'a', code: 'AAA111', usable: false),
        codigo(id: 'b', code: 'BBB222', usable: false),
      ],
    );
    http.on(
      'DELETE',
      '/api/invite-codes',
      body: {
        'data': {'archived': 2},
      },
    );

    await tester.tap(find.byKey(const Key('select_unusable')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive_selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_archive')));
    await tester.pumpAndSettle();

    final envio = http.requests.where((r) => r.method == 'DELETE').single;
    expect((envio.data as Map)['codeIds'], containsAll(<String>['a', 'b']));
    expect(
      http.requests.where((r) => r.path == '/api/invite-codes'),
      hasLength(greaterThan(2)),
    );
  });

  testWidgets('desmarcar o ultimo sai da selecao', (tester) async {
    await abrir(tester, codigos: [codigo()]);

    await tester.longPress(find.byKey(const Key('code_c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('code_c1')));
    await tester.pumpAndSettle();

    expect(find.text('Códigos de acesso'), findsOneWidget);
    expect(find.byKey(const Key('generate_code_fab')), findsOneWidget);
  });
}
