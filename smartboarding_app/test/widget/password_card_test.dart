import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/widgets/password_card.dart';

import '../support/fake_http.dart';

Future<FakeHttpAdapter> abrir(
  WidgetTester tester, {
  bool trocando = false,
  int status = 200,
}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on('POST', '/api/me/password', status: status, body: {'success': true});
  http.on('PUT', '/api/me/password', status: status, body: {'success': true});
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: PasswordCard(changing: trocando)),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('profile_open_password_form')));
  await tester.pumpAndSettle();
  return http;
}

Future<void> preencher(
  WidgetTester tester,
  String senha,
  String confirmacao, {
  String? atual,
}) async {
  if (atual != null) {
    await tester.enterText(
      find.byKey(const Key('password_current_field')),
      atual,
    );
  }
  await tester.enterText(find.byKey(const Key('password_new_field')), senha);
  await tester.enterText(
    find.byKey(const Key('password_confirm_field')),
    confirmacao,
  );
  await tester.ensureVisible(find.byKey(const Key('password_submit')));
  await tester.tap(find.byKey(const Key('password_submit')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('criar a primeira senha', () {
    testWidgets('senha valida vai pro backend', (tester) async {
      final http = await abrir(tester);

      await preencher(tester, 'segredo123', 'segredo123');

      final envio = http.requests.single;
      expect(envio.method, 'POST');
      expect(envio.path, '/api/me/password');
      expect((envio.data as Map)['password'], 'segredo123');
    });

    testWidgets('confirmacao diferente nao envia nada', (tester) async {
      final http = await abrir(tester);

      await preencher(tester, 'segredo123', 'segredo124');

      expect(http.requests, isEmpty);
      expect(find.text('As senhas não conferem'), findsOneWidget);
    });

    testWidgets('senha curta nao envia nada', (tester) async {
      final http = await abrir(tester);

      await preencher(tester, 'abc', 'abc');

      expect(http.requests, isEmpty);
      expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
    });

    testWidgets('nao pede senha atual: nao existe uma', (tester) async {
      await abrir(tester);

      expect(find.byKey(const Key('password_current_field')), findsNothing);
    });

    testWidgets('erro do backend vira mensagem na tela', (tester) async {
      await abrir(tester, status: 409);

      await preencher(tester, 'segredo123', 'segredo123');

      expect(
        find.text('Conflito: já existe um registro com esses dados.'),
        findsOneWidget,
      );
    });
  });

  group('trocar a senha', () {
    testWidgets('manda a atual junto, no PUT', (tester) async {
      final http = await abrir(tester, trocando: true);

      await preencher(tester, 'nova456789', 'nova456789', atual: 'antiga123');

      final envio = http.requests.single;
      expect(envio.method, 'PUT');
      expect(envio.path, '/api/me/password');
      expect((envio.data as Map)['currentPassword'], 'antiga123');
      expect((envio.data as Map)['newPassword'], 'nova456789');
    });

    testWidgets('sem a senha atual nao envia nada', (tester) async {
      final http = await abrir(tester, trocando: true);

      await preencher(tester, 'nova456789', 'nova456789', atual: '');

      expect(http.requests, isEmpty);
      expect(find.text('Informe sua senha atual'), findsOneWidget);
    });

    testWidgets('senha atual errada vira mensagem', (tester) async {
      await abrir(tester, trocando: true, status: 400);

      await preencher(tester, 'nova456789', 'nova456789', atual: 'chutei');

      expect(find.text('Dados inválidos na requisição.'), findsOneWidget);
    });
  });
}
