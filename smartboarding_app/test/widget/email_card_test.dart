import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/widgets/email_card.dart';

import '../support/fake_http.dart';

Future<FakeHttpAdapter> abrir(
  WidgetTester tester, {
  int requestStatus = 200,
  int confirmStatus = 200,
  VoidCallback? onChanged,
}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on(
    'POST',
    '/api/me/email/request',
    status: requestStatus,
    body: {'success': true},
  );
  http.on(
    'POST',
    '/api/me/email/confirm',
    status: confirmStatus,
    body: {'success': true},
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmailCard(
          currentEmail: 'atual@edu.unifor.br',
          onChanged: onChanged ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('profile_open_email_form')));
  await tester.pumpAndSettle();
  return http;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mostra o e-mail atual', (tester) async {
    await abrir(tester);

    expect(find.text('Atual: atual@edu.unifor.br'), findsOneWidget);
  });

  testWidgets('pedir codigo manda o e-mail novo pro backend', (tester) async {
    final http = await abrir(tester);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'novo@edu.unifor.br',
    );
    await tester.tap(find.byKey(const Key('email_send_code')));
    await tester.pumpAndSettle();

    final envio = http.requests.single;
    expect(envio.method, 'POST');
    expect(envio.path, '/api/me/email/request');
    expect((envio.data as Map)['newEmail'], 'novo@edu.unifor.br');
  });

  testWidgets('e-mail invalido nao envia nada', (tester) async {
    final http = await abrir(tester);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'nao-e-email',
    );
    await tester.tap(find.byKey(const Key('email_send_code')));
    await tester.pumpAndSettle();

    expect(http.requests, isEmpty);
    expect(find.text('Informe um e-mail válido'), findsOneWidget);
  });

  testWidgets('depois de pedir o codigo, mostra o campo de confirmacao', (
    tester,
  ) async {
    await abrir(tester);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'novo@edu.unifor.br',
    );
    await tester.tap(find.byKey(const Key('email_send_code')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email_new_field')), findsNothing);
    expect(find.byKey(const Key('email_code_field')), findsOneWidget);
  });

  testWidgets('confirmar com o codigo manda pro backend e avisa quem escuta', (
    tester,
  ) async {
    var avisado = false;
    final http = await abrir(tester, onChanged: () => avisado = true);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'novo@edu.unifor.br',
    );
    await tester.tap(find.byKey(const Key('email_send_code')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_code_field')), '123456');
    await tester.tap(find.byKey(const Key('email_confirm_code')));
    await tester.pumpAndSettle();

    final confirmacao = http.requests.last;
    expect(confirmacao.method, 'POST');
    expect(confirmacao.path, '/api/me/email/confirm');
    expect((confirmacao.data as Map)['code'], '123456');
    expect(avisado, isTrue);
  });

  testWidgets('e-mail ja em uso vira mensagem na tela', (tester) async {
    await abrir(tester, requestStatus: 409);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'ocupado@edu.unifor.br',
    );
    await tester.tap(find.byKey(const Key('email_send_code')));
    await tester.pumpAndSettle();

    expect(
      find.text('Conflito: já existe um registro com esses dados.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('email_new_field')), findsOneWidget);
  });

  testWidgets('codigo errado vira mensagem e nao chama onChanged', (
    tester,
  ) async {
    var avisado = false;
    await abrir(tester, confirmStatus: 400, onChanged: () => avisado = true);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'novo@edu.unifor.br',
    );
    await tester.tap(find.byKey(const Key('email_send_code')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_code_field')), '000000');
    await tester.tap(find.byKey(const Key('email_confirm_code')));
    await tester.pumpAndSettle();

    expect(find.text('Dados inválidos na requisição.'), findsOneWidget);
    expect(avisado, isFalse);
  });

  testWidgets('cancelar volta pro estado fechado', (tester) async {
    await abrir(tester);

    await tester.enterText(
      find.byKey(const Key('email_new_field')),
      'novo@edu.unifor.br',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_open_email_form')), findsOneWidget);
  });
}
