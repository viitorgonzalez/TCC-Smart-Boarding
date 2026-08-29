import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartboarding_app/main.dart' as app;

const _studentEmail = 'fernanda@student.com';
const _studentPassword = 'sb@2026';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Autenticação e primeiro formulário do aluno', () {
    testWidgets('credencial inválida mostra erro e não sai do login', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        _studentEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'senha-errada-de-proposito',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('Falha no login'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    });

    testWidgets(
      'credencial válida entra na home do aluno e abre o formulário de direção',
      (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          _studentEmail,
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          _studentPassword,
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Saiu da tela de login.
        expect(find.byKey(const Key('login_email_field')), findsNothing);
        expect(find.text('Smart Boarding'), findsOneWidget);

        // fernanda@student.com não está pré-inscrita na lista de hoje (seed) —
        // o botão "Entrar na lista" deve aparecer de forma determinística.
        final entrarNaLista = find.widgetWithText(
          FilledButton,
          'Entrar na lista',
        );

        expect(
          tester.any(entrarNaLista),
          isTrue,
          reason: 'esperava ver o botão "Entrar na lista" no card de hoje',
        );

        await tester.tap(entrarNaLista.first);
        await tester.pumpAndSettle();

        // Bottom sheet de direção — abre pelo menos uma opção (ida/volta/ida e volta).
        expect(find.text('Escolha a direção'), findsOneWidget);
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Você está na lista'), findsOneWidget);
      },
    );
  });
}
