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

  /// Quem já está na lista entrou quando era permitido. Esconder o "Sair" por
  /// um campo em branco o prenderia numa viagem que ele não vai fazer.
  testWidgets('quem ja esta na lista ainda consegue sair', (tester) async {
    await montar(tester, faltando: const ['Telefone'], inscrito: true);

    expect(find.text('Sair da lista'), findsOneWidget);
    expect(find.byKey(const Key('list_profile_warning')), findsNothing);
  });

  // ─── Acompanhar trajeto ───────────────────────────────────────────────────

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

  /// Oferecer sempre levaria a uma tela que só diz "não começou".
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

  // ─── Tempo médio até a instituição do aluno ───────────────────────────────

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

  /// O card mostrava o trajeto sem dizer quanto tempo leva — e o tempo é DELE:
  /// a média do trajeto inteiro, pra quem desce no meio, não é sobre a viagem
  /// dele.
  testWidgets('mostra o tempo nomeando a instituicao', (tester) async {
    await montarComTempo(
      tester,
      const MyTripTime(stopName: 'UNIFOR-MG', avgMinutes: 42),
    );

    expect(find.byKey(const Key('list_trip_time')), findsOneWidget);
    expect(find.textContaining('42 min'), findsOneWidget);
    expect(find.textContaining('UNIFOR-MG'), findsWidgets);
  });

  /// Nulo é "não sei" e a tela omite. Um zero o aluno leria como "chega na
  /// hora" e perderia o ônibus.
  testWidgets('sem tempo calculado o card nao inventa numero', (tester) async {
    await montarComTempo(tester, null);

    expect(find.byKey(const Key('list_trip_time')), findsNothing);
    expect(find.textContaining('min até'), findsNothing);
  });

  /// Um tempo até um lugar que não é o dele, sem aviso, é pior que tempo
  /// nenhum.
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
