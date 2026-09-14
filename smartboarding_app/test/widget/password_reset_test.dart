import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/auth/screens/reset_password_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  Future<void> preencher(
    WidgetTester tester, {
    required String codigo,
    required String senha,
    required String confirma,
  }) async {
    await tester.enterText(find.byKey(const Key('reset_code_field')), codigo);
    await tester.enterText(
      find.byKey(const Key('reset_password_field')),
      senha,
    );
    await tester.enterText(
      find.byKey(const Key('reset_confirm_field')),
      confirma,
    );
    await tester.tap(find.byKey(const Key('reset_submit_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('código com menos de 6 dígitos é recusado', (tester) async {
    await tester.pumpWidget(
      wrap(const ResetPasswordScreen(email: 'aluno@edu.unifor.br')),
    );

    await preencher(
      tester,
      codigo: '123',
      senha: 'senhaNova1',
      confirma: 'senhaNova1',
    );

    expect(find.text('O código tem 6 dígitos'), findsOneWidget);
  });

  testWidgets('senha e confirmação diferentes são recusadas', (tester) async {
    await tester.pumpWidget(
      wrap(const ResetPasswordScreen(email: 'aluno@edu.unifor.br')),
    );

    await preencher(
      tester,
      codigo: '123456',
      senha: 'senhaNova1',
      confirma: 'outraSenha',
    );

    expect(find.text('As senhas não conferem'), findsOneWidget);
  });

  testWidgets('senha curta é recusada (RN10)', (tester) async {
    await tester.pumpWidget(
      wrap(const ResetPasswordScreen(email: 'aluno@edu.unifor.br')),
    );

    await preencher(tester, codigo: '123456', senha: 'abc', confirma: 'abc');

    expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
  });
}
