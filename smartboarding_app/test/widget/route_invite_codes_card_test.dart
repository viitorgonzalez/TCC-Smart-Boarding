import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/routes/widgets/route_invite_codes_card.dart';

import '../support/fake_http.dart';
import '../support/pump_until.dart';

Future<FakeHttpAdapter> abrir(
  WidgetTester tester, {
  required List<Map<String, dynamic>> codigos,
}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on('GET', '/api/routes/rota-1/invite-codes', body: {'data': codigos});
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: RouteInviteCodesCard(routeId: 'rota-1')),
    ),
  );
  // Espera por MAIS de um ListTile: o de "gerar codigo" existe desde o primeiro
  // frame, entao esperar por um so sairia antes de a requisicao voltar.
  await pumpUntil(
    tester,
    () => find.byType(ListTile).evaluate().length > 1,
    describe: 'os codigos carregarem alem do tile de gerar',
  );
  return http;
}

Map<String, dynamic> codigo({
  String id = 'c1',
  String code = 'ABC123',
  bool usable = true,
  int uses = 0,
  String? revokedAt,
}) => {
  'id': id,
  'routeId': 'rota-1',
  'code': code,
  'expiresAt': '2026-12-31T23:59:59',
  'revokedAt': revokedAt,
  'usable': usable,
  'uses': uses,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra o codigo em destaque pra ser copiado', (tester) async {
    await abrir(tester, codigos: [codigo(code: 'XYZ789')]);

    expect(find.text('XYZ789'), findsOneWidget);
    expect(find.byKey(const Key('copy_code_c1')), findsOneWidget);
  });

  /// Quantos alunos entraram e ate quando vale sao o que o admin olha pra
  /// decidir se distribui de novo ou revoga.
  testWidgets('mostra quantos entraram por cada codigo', (tester) async {
    await abrir(tester, codigos: [codigo(uses: 12)]);

    expect(find.textContaining('12'), findsWidgets);
  });

  /// Codigo revogado ou expirado continua na lista como registro, mas nao pode
  /// parecer distribuivel -- oferecer copiar um codigo morto faz o admin mandar
  /// pra turma algo que nao funciona.
  testWidgets('codigo revogado nao oferece copiar', (tester) async {
    await abrir(
      tester,
      codigos: [codigo(usable: false, revokedAt: '2026-09-01T10:00:00')],
    );

    expect(find.byKey(const Key('copy_code_c1')), findsNothing);
    expect(find.textContaining('Cancelado'), findsOneWidget);
  });

  testWidgets('codigo expirado nao oferece copiar', (tester) async {
    await abrir(tester, codigos: [codigo(usable: false)]);

    expect(find.byKey(const Key('copy_code_c1')), findsNothing);
    expect(find.textContaining('Expirado'), findsOneWidget);
  });

  testWidgets('sem codigo nenhum, convida a gerar o primeiro', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on('GET', '/api/routes/rota-1/invite-codes', body: {'data': []});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RouteInviteCodesCard(routeId: 'rota-1')),
      ),
    );
    // Espera pelo estado vazio, nao pelo botao: o botao existe desde o primeiro
    // frame, e sair antes da requisicao voltar deixa timer pendente.
    await pumpUntil(
      tester,
      () => find.text('Nenhum código criado').evaluate().isNotEmpty,
      describe: 'o estado vazio aparecer depois de carregar',
    );

    expect(find.byKey(const Key('generate_code')), findsOneWidget);
  });
}
