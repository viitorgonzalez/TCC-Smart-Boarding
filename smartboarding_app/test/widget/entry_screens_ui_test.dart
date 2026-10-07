import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/auth/screens/login_screen.dart';
import 'package:smartboarding_app/features/auth/screens/signup_screen.dart';

import '../support/fake_http.dart';

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
