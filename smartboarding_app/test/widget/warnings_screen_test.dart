import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/warnings/screens/warnings_screen.dart';

import '../support/fake_http.dart';

Map<String, dynamic> _warningJson({String reason = 'Entrou fora do horário'}) {
  return {
    'id': 'aaaaaaaa-0000-0000-0000-000000000900',
    'userId': 'aaaaaaaa-0000-0000-0000-000000000202',
    'studentName': 'Ana Oliveira',
    'reason': reason,
    'listDate': '2026-09-09',
    'issuedBy': 'System Administrator',
    'createdAt': '2026-09-09T08:00:00',
  };
}

Future<void> _pump(WidgetTester tester, {required bool canManage}) async {
  await tester.pumpWidget(
    MaterialApp(home: WarningsScreen(canManage: canManage)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('aluno ve a propria lista sem paginar', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on(
      'GET',
      '/api/warnings/me',
      body: {
        'data': [_warningJson()],
      },
    );

    await _pump(tester, canManage: false);

    expect(find.text('Entrou fora do horário'), findsOneWidget);
    expect(find.text('Advertência'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('admin ve a lista paginada sem quebrar', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on(
      'GET',
      '/api/warnings',
      body: {
        'data': {
          'content': [_warningJson()],
          'totalPages': 1,
        },
      },
    );

    await _pump(tester, canManage: true);

    expect(find.text('Ana Oliveira'), findsOneWidget);
    expect(find.text('Entrou fora do horário'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('quando ha mais paginas mostra indicador de carregamento', (
    tester,
  ) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on(
      'GET',
      '/api/warnings',
      body: {
        'data': {
          'content': [_warningJson()],
          'totalPages': 2,
        },
      },
    );

    await _pump(tester, canManage: true);

    expect(find.text('Ana Oliveira'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('lista vazia mostra estado vazio em vez de travar', (
    tester,
  ) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on(
      'GET',
      '/api/warnings',
      body: {
        'data': {'content': [], 'totalPages': 0},
      },
    );

    await _pump(tester, canManage: true);

    expect(find.text('Nenhuma advertência registrada'), findsOneWidget);
  });

  testWidgets('erro na requisicao vira mensagem com botao de tentar de novo', (
    tester,
  ) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on('GET', '/api/warnings', status: 500, body: {});

    await _pump(tester, canManage: true);

    expect(find.text('Erro no servidor. Tente novamente.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });
}
