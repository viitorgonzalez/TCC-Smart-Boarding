import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/widgets/set_password_card.dart';

import '../support/fake_http.dart';

Future<FakeHttpAdapter> abrir(WidgetTester tester, {int status = 200}) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on('POST', '/api/me/password', status: status, body: {'success': true});
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SetPasswordCard())));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('profile_open_set_password')));
  await tester.pumpAndSettle();
  return http;
}

Future<void> preencher(
  WidgetTester tester,
  String senha,
  String confirmacao,
) async {
  await tester.enterText(find.byKey(const Key('set_password_field')), senha);
  await tester.enterText(
    find.byKey(const Key('set_password_confirm_field')),
    confirmacao,
  );
  await tester.ensureVisible(find.byKey(const Key('set_password_submit')));
  await tester.tap(find.byKey(const Key('set_password_submit')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('senha valida vai pro backend', (tester) async {
    final http = await abrir(tester);

    await preencher(tester, 'segredo123', 'segredo123');

    final envio = http.requests.where((r) => r.method == 'POST').single;
    expect(envio.path, '/api/me/password');
    expect((envio.data as Map)['password'], 'segredo123');
  });

  /// Confirmacao divergente tem que morrer no formulario. Se vazasse pro
  /// backend, a conta ficaria com uma senha que o dono acha que nao digitou.
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

  /// O 409 do backend (conta que ja tem senha) precisa virar mensagem, nao
  /// excecao solta que derruba a tela de perfil.
  testWidgets('erro do backend vira mensagem na tela', (tester) async {
    await abrir(tester, status: 409);

    await preencher(tester, 'segredo123', 'segredo123');

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
