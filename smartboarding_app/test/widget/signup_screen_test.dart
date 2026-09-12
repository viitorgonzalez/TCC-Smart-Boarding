import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/auth/screens/signup_screen.dart';

import '../support/fake_http.dart';

Future<void> abrir(WidgetTester tester) async {
  await installFakeHttp();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MaterialApp(home: SignupScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// O TextField do Flutter nao expoe obscureText direto no finder, entao lemos do
/// widget montado.
bool escondido(WidgetTester tester, Key campo) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(campo), matching: find.byType(TextField)),
  );
  return field.obscureText;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('as duas senhas comecam escondidas', (tester) async {
    await abrir(tester);

    expect(escondido(tester, const Key('signup_password_field')), isTrue);
    expect(escondido(tester, const Key('signup_confirm_field')), isTrue);
  });

  /// Um toggle so revelava OS DOIS campos: quem so queria conferir o que digitou
  /// acabava expondo a outra senha sem querer.
  testWidgets('mostrar a senha nao revela a confirmacao', (tester) async {
    await abrir(tester);

    final olhos = find.descendant(
      of: find.byKey(const Key('signup_password_field')),
      matching: find.byType(IconButton),
    );
    await tester.tap(olhos);
    await tester.pump();

    expect(escondido(tester, const Key('signup_password_field')), isFalse);
    expect(escondido(tester, const Key('signup_confirm_field')), isTrue);
  });

  testWidgets('o campo de confirmar tem olho proprio', (tester) async {
    await abrir(tester);

    final olhoConfirma = find.descendant(
      of: find.byKey(const Key('signup_confirm_field')),
      matching: find.byType(IconButton),
    );
    expect(olhoConfirma, findsOneWidget);

    await tester.tap(olhoConfirma);
    await tester.pump();

    expect(escondido(tester, const Key('signup_confirm_field')), isFalse);
    expect(escondido(tester, const Key('signup_password_field')), isTrue);
  });

  // Sem autofocus o usuario precisa de um toque a mais so pra comecar a digitar.
  testWidgets('o primeiro campo ja vem com foco', (tester) async {
    await abrir(tester);

    final nome = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('signup_name_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(nome.autofocus, isTrue);
  });

  testWidgets('senha curta e recusada antes de ir pra rede', (tester) async {
    await abrir(tester);

    await tester.enterText(find.byKey(const Key('signup_name_field')), 'Joao');
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'joao@edu.unifor.br',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      '123',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_field')),
      '123',
    );
    // O botao fica abaixo da dobra na viewport do teste; sem rolar ate ele o
    // tap cai fora e nao dispara nada.
    await tester.ensureVisible(find.byKey(const Key('signup_submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signup_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
  });

  testWidgets('senhas diferentes sao recusadas', (tester) async {
    await abrir(tester);

    await tester.enterText(find.byKey(const Key('signup_name_field')), 'Joao');
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'joao@edu.unifor.br',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      'sb@2026',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_field')),
      'outra123',
    );
    // O botao fica abaixo da dobra na viewport do teste; sem rolar ate ele o
    // tap cai fora e nao dispara nada.
    await tester.ensureVisible(find.byKey(const Key('signup_submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signup_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não conferem'), findsOneWidget);
  });
}
