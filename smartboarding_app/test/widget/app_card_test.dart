import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/widgets/app_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Object?> montar(WidgetTester tester, Widget filho) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppCard(child: filho)),
      ),
    );
    await tester.pump();
    return tester.takeException();
  }

  /// Com a cor do card num DecoratedBox solto, o ink de um ListTile com onTap
  /// era pintado ATRAS do fundo: o admin tocava e nao via retorno nenhum. Seis
  /// telas poem ListTile dentro de AppCard, entao a correcao e aqui, no card.
  testWidgets('ListTile tocavel dentro do card nao reclama de Material', (
    tester,
  ) async {
    final erro = await montar(
      tester,
      ListTile(title: const Text('Adicionar'), onTap: () {}),
    );

    expect(erro, isNull);
  });

  testWidgets('ListTile sem onTap continua montando', (tester) async {
    expect(await montar(tester, const ListTile(title: Text('x'))), isNull);
  });

  testWidgets('o card ainda pinta fundo, borda e raio', (tester) async {
    await montar(tester, const Text('x'));

    final material = tester.widget<Material>(
      find
          .descendant(of: find.byType(AppCard), matching: find.byType(Material))
          .first,
    );
    expect(material.color, isNotNull);
    expect(material.shape, isA<RoundedRectangleBorder>());
    expect(material.clipBehavior, Clip.antiAlias);
  });
}
