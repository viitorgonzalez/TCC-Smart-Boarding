import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/home/widgets/student_list_card.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/models/list_with_enrollment.dart';

void main() {
  ListWithEnrollment listaAberta({bool inscrito = false}) => ListWithEnrollment(
    list: DailyList(
      id: 'l1',
      routeId: 'r1',
      routeName: 'Rota Universitária de Formiga',
      date: '2026-09-25',
      status: 'OPEN',
      // Sem closeTime de propósito: com um horário fixo, acceptsChanges vira
      // falso depois dele e o card some inteiro -- o teste passaria de manhã e
      // falharia à noite.
      closeTime: null,
      totalEntries: 3,
    ),
    isEnrolled: inscrito,
  );

  Future<void> montar(
    WidgetTester tester, {
    required List<String> faltando,
    bool inscrito = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentListCard(
              item: listaAberta(inscrito: inscrito),
              missingProfile: faltando,
              onEnter: (_) {},
              onLeave: () {},
              onFixProfile: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('perfil completo mostra o botao de entrar', (tester) async {
    await montar(tester, faltando: const []);

    expect(find.text('Entrar na lista'), findsOneWidget);
    expect(find.byKey(const Key('list_profile_warning')), findsNothing);
  });

  /// O ponto: descobrir o bloqueio só ao tocar no botão é fazer a pessoa
  /// esbarrar numa parede que dava pra sinalizar.
  testWidgets('perfil incompleto troca o botao pelo aviso', (tester) async {
    await montar(tester, faltando: const ['Telefone', 'Endereço']);

    expect(find.text('Entrar na lista'), findsNothing);
    expect(find.byKey(const Key('list_profile_warning')), findsOneWidget);
  });

  /// "Complete seu perfil" obriga o aluno a adivinhar. O aviso nomeia.
  testWidgets('o aviso nomeia os campos que faltam', (tester) async {
    await montar(tester, faltando: const ['Telefone', 'Endereço']);

    final aviso = find.byKey(const Key('list_profile_warning'));
    final textos = tester
        .widgetList<Text>(find.descendant(of: aviso, matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .join(' ');

    expect(textos, contains('Telefone'));
    expect(textos, contains('Endereço'));
  });

  testWidgets('o aviso leva pro perfil', (tester) async {
    var foi = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentListCard(
              item: listaAberta(),
              missingProfile: const ['Telefone'],
              onEnter: (_) {},
              onLeave: () {},
              onFixProfile: () => foi = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('list_profile_fix_button')));
    await tester.pumpAndSettle();

    expect(foi, isTrue);
  });

  /// Quem já está na lista entrou quando era permitido. Esconder o "Sair" por
  /// um campo em branco o prenderia numa viagem que ele não vai fazer.
  testWidgets('quem ja esta na lista ainda consegue sair', (tester) async {
    await montar(tester, faltando: const ['Telefone'], inscrito: true);

    expect(find.text('Sair da lista'), findsOneWidget);
    expect(find.byKey(const Key('list_profile_warning')), findsNothing);
  });
}
