import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/auth/screens/login_screen.dart';
import 'package:smartboarding_app/features/auth/screens/signup_screen.dart';

import '../support/fake_http.dart';

/// Lê os atributos do TextField montado — `AppTextField` os repassa, então é
/// aqui que dá pra ver se chegaram.
TextField campo(WidgetTester tester, Key chave) => tester.widget<TextField>(
  find.descendant(of: find.byKey(chave), matching: find.byType(TextField)),
);

Future<void> abrir(WidgetTester tester, Widget tela) async {
  await installFakeHttp();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: tela),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Sem autofillHints o gerenciador de senhas do aparelho nao oferece
  /// preencher, e a pessoa digita e-mail e senha na mao em todo login.
  testWidgets('login declara o que cada campo guarda', (tester) async {
    await abrir(tester, const LoginScreen());

    expect(
      campo(tester, const Key('login_email_field')).autofillHints,
      contains(AutofillHints.username),
    );
    expect(
      campo(tester, const Key('login_password_field')).autofillHints,
      contains(AutofillHints.password),
    );
  });

  /// `next` pula pro proximo campo e `done` envia. Sem isso o teclado mostra
  /// "return", nao navega, e cada campo custa um toque a mais.
  testWidgets('login navega pelo teclado e envia no ultimo', (tester) async {
    await abrir(tester, const LoginScreen());

    expect(
      campo(tester, const Key('login_email_field')).textInputAction,
      TextInputAction.next,
    );
    expect(
      campo(tester, const Key('login_password_field')).textInputAction,
      TextInputAction.done,
    );
  });

  testWidgets('cadastro encadeia os quatro campos', (tester) async {
    await abrir(tester, const SignupScreen());

    for (final chave in [
      'signup_name_field',
      'signup_email_field',
      'signup_password_field',
    ]) {
      expect(
        campo(tester, Key(chave)).textInputAction,
        TextInputAction.next,
        reason: '$chave deveria pular pro proximo',
      );
    }
    expect(
      campo(tester, const Key('signup_confirm_field')).textInputAction,
      TextInputAction.done,
      reason: 'o ultimo campo envia',
    );
  });

  /// Senha nova precisa ser marcada como nova: com `password`, o gerenciador
  /// oferece a senha ANTIGA no cadastro em vez de sugerir uma forte.
  testWidgets('cadastro marca as senhas como novas', (tester) async {
    await abrir(tester, const SignupScreen());

    expect(
      campo(tester, const Key('signup_password_field')).autofillHints,
      contains(AutofillHints.newPassword),
    );
    expect(
      campo(tester, const Key('signup_confirm_field')).autofillHints,
      contains(AutofillHints.newPassword),
    );
  });
}
