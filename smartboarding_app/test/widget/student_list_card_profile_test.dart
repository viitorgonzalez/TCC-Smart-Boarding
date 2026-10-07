import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/home/widgets/student_list_card.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/models/list_with_enrollment.dart';

void main() {
  ListWithEnrollment listaAberta({
    bool inscrito = false,
    bool emTrajeto = false,
    MyTripTime? tempo,
  }) => ListWithEnrollment(
    list: DailyList(
      id: 'l1',
      routeId: 'r1',
      routeName: 'Rota Universitária de Formiga',
      date: '2026-09-25',
      status: 'OPEN',
      tripInProgress: emTrajeto,
      myTripTime: tempo,
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

  testWidgets('perfil incompleto troca o botao pelo aviso', (tester) async {
    await montar(tester, faltando: const ['Telefone', 'Endereço']);

    expect(find.text('Entrar na lista'), findsNothing);
    expect(find.byKey(const Key('list_profile_warning')), findsOneWidget);
  });

  testWidgets('o aviso nomeia os campos que faltam', (tester) async {
    await montar(tester, faltando: const ['Telefone', 'Endereço']);

    final aviso = find.byKey(const Key('list_profile_warning'));
    final textos = tester
        .widgetList<Text>(
          find.descendant(of: aviso, matching: find.byType(Text)),
        )
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

  testWidgets('quem ja esta na lista ainda consegue sair', (tester) async {
    await montar(tester, faltando: const ['Telefone'], inscrito: true);

    expect(find.text('Sair da lista'), findsOneWidget);
    expect(find.byKey(const Key('list_profile_warning')), findsNothing);
  });

  Future<void> montarComTrajeto(
    WidgetTester tester, {
    required bool emTrajeto,
    VoidCallback? onFollow,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentListCard(
              item: listaAberta(emTrajeto: emTrajeto),
              missingProfile: const [],
              onEnter: (_) {},
              onLeave: () {},
              onFollowTrip: onFollow ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('trajeto parado nao oferece acompanhar', (tester) async {
    await montarComTrajeto(tester, emTrajeto: false);

    expect(find.byKey(const Key('student_follow_trip')), findsNothing);
  });

  testWidgets('trajeto em andamento oferece acompanhar', (tester) async {
    await montarComTrajeto(tester, emTrajeto: true);

    expect(find.byKey(const Key('student_follow_trip')), findsOneWidget);
  });

  testWidgets('o botao leva pro acompanhamento', (tester) async {
    var foi = false;
    await montarComTrajeto(tester, emTrajeto: true, onFollow: () => foi = true);

    await tester.tap(find.byKey(const Key('student_follow_trip')));
    await tester.pumpAndSettle();

    expect(foi, isTrue);
  });

  Future<void> montarComTempo(WidgetTester tester, MyTripTime? tempo) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentListCard(
              item: listaAberta(tempo: tempo),
              missingProfile: const [],
              onEnter: (_) {},
              onLeave: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('mostra o tempo nomeando a instituicao', (tester) async {
    await montarComTempo(
      tester,
      const MyTripTime(stopName: 'UNIFOR-MG', avgMinutes: 42),
    );

    expect(find.byKey(const Key('list_trip_time')), findsOneWidget);
    expect(find.textContaining('42 min'), findsOneWidget);
    expect(find.textContaining('UNIFOR-MG'), findsWidgets);
  });

  testWidgets('sem tempo calculado o card nao inventa numero', (tester) async {
    await montarComTempo(tester, null);

    expect(find.byKey(const Key('list_trip_time')), findsNothing);
    expect(find.textContaining('min até'), findsNothing);
  });

  testWidgets('avisa quando a parada nao e da instituicao dele', (
    tester,
  ) async {
    await montarComTempo(
      tester,
      const MyTripTime(stopName: 'IFMG', avgMinutes: 47, fallback: true),
    );

    expect(find.textContaining('não tem parada declarada'), findsOneWidget);
  });
}
