import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/constants/auth_constants.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/auth/screens/login_screen.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrir(WidgetTester tester) async {
    await installFakeHttp();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// A suite roda sem --dart-define, entao esta build nao tem Google
  /// configurado -- e o botao nao pode aparecer. Oferecer o caminho aqui faria
  /// o usuario escolher a conta pra so entao descobrir que a build nao sabe
  /// pedir o token certo.
  testWidgets('sem client id configurado o botao do Google some', (
    tester,
  ) async {
    await abrir(tester);

    expect(googleSignInEnabled, isFalse);
    expect(find.byKey(const Key('login_google_button')), findsNothing);
  });

  /// O que nao pode e a tela inteira depender do Google: entrar por e-mail e
  /// senha continua no lugar.
  testWidgets('login por e-mail continua disponivel', (tester) async {
    await abrir(tester);

    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('login_forgot_password')), findsOneWidget);
  });
}
