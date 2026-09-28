import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/widgets/app_header.dart';

void main() {
  late List<String> tocados;

  Future<void> montar(WidgetTester tester) async {
    tocados = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeaderOverflowMenu(
            items: [
              HeaderMenuItem(
                label: 'Meu perfil',
                icon: Icons.person_outline,
                onSelected: () => tocados.add('perfil'),
              ),
              HeaderMenuItem(
                label: 'Sair',
                icon: Icons.logout,
                onSelected: () => tocados.add('sair'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// O menu existe pra tirar peso visual do cabeçalho: as ações continuam lá,
  /// só não como três blocos sólidos competindo entre si.
  testWidgets('as acoes ficam escondidas ate abrir o menu', (tester) async {
    await montar(tester);

    expect(find.text('Meu perfil'), findsNothing);
    expect(find.text('Sair'), findsNothing);

    await tester.tap(find.byKey(const Key('header_overflow_menu')));
    await tester.pumpAndSettle();

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('escolher uma acao a executa', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('header_overflow_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(tocados, ['sair']);
  });

  testWidgets('a outra acao tambem e alcancavel', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('header_overflow_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meu perfil'));
    await tester.pumpAndSettle();

    expect(tocados, ['perfil']);
  });
}
