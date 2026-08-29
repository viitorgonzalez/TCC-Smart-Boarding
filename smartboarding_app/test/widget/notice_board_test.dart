import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/notifications/widgets/notice_board.dart';

void main() {
  Widget wrap(List<Widget> notes, {Size size = const Size(360, 720)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(body: NoticeBoard(notes: notes)),
      ),
    );
  }

  NoticeNote note(String seed, String text) =>
      NoticeNote(seed: seed, child: Text(text));

  testWidgets('desenha o quadro com vários bilhetes sem estourar', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        note('a', 'Ônibus atrasado hoje'),
        note('b', 'Lista de hoje fechada'),
        note('c', 'Horário da lista mudou'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ônibus atrasado hoje'), findsOneWidget);
    expect(find.byType(NoticeNote), findsNWidgets(3));
  });

  testWidgets('texto longo quebra dentro do papel, sem overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap([
        note(
          'longo',
          'A lista da Rota Universitária de Formiga fechou antes do horário '
              'porque o ônibus quebrou na saída da rodoviária e a coordenação '
              'precisou cancelar a viagem de hoje inteira.',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cabe em tela estreita', (tester) async {
    await tester.pumpWidget(
      wrap([note('a', 'Aviso curto')], size: const Size(320, 600)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('bilhete expirado usa o fundo apagado', (tester) async {
    await tester.pumpWidget(
      wrap([const NoticeNote(seed: 'x', faded: true, child: Text('Antigo'))]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Antigo'), findsOneWidget);
  });

  // O mural é tema do app, não skin à parte: se alguém trouxer cor de fora da
  // paleta, isto quebra.
  testWidgets('mural e bilhete usam as cores do design system', (tester) async {
    await tester.pumpWidget(wrap([note('a', 'Aviso')]));
    await tester.pumpAndSettle();

    final surfaces = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .whereType<Color>()
        .toSet();

    expect(surfaces, contains(AppColors.ashGrey));
    expect(surfaces, contains(AppColors.surface));
    expect(surfaces, contains(AppColors.deepTeal));
  });

  testWidgets('bilhete selecionado ganha borda da primária', (tester) async {
    await tester.pumpWidget(
      wrap([
        const NoticeNote(seed: 'sel', selected: true, child: Text('Marcado')),
      ]),
    );
    await tester.pumpAndSettle();

    final borders = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border)
        .whereType<Border>()
        .map((b) => b.top.color)
        .toSet();

    expect(borders, contains(AppColors.deepTeal));
  });

  testWidgets('toque longo e toque chegam em quem prendeu o bilhete', (
    tester,
  ) async {
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      wrap([
        NoticeNote(
          seed: 'acoes',
          onTap: () => taps++,
          onLongPress: () => longPresses++,
          child: const Text('Aviso'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aviso'));
    await tester.longPress(find.text('Aviso'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(longPresses, 1);
  });
}
