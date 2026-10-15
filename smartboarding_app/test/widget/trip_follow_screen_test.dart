import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/trip/models/trip_status_model.dart';
import 'package:smartboarding_app/features/trip/screens/trip_follow_screen.dart';
import 'package:smartboarding_app/features/trip/services/trip_service.dart';

class _MockTripService extends Mock implements TripService {}

void main() {
  late _MockTripService service;

  TripStatus viagem({
    String? startedAt = '2026-09-25T07:00:00',
    String? finishedAt,
    Map<String, dynamic>? myStop,
    List<Map<String, dynamic>>? stops,
  }) => TripStatus.fromJson({
    'listId': 'l1',
    'routeName': 'Rota Universitária',
    'startedAt': startedAt,
    'finishedAt': finishedAt,
    'leg': 'OUTBOUND',
    'stops':
        stops ??
        [
          {
            'stopId': 'p1',
            'name': 'Rodoviária',
            'sequence': 1,
            'reachedAt': '2026-09-25T07:05:00',
          },
          {'stopId': 'p2', 'name': 'Centro', 'sequence': 2, 'reachedAt': null},
          {
            'stopId': 'p3',
            'name': 'UNIFOR-MG',
            'sequence': 3,
            'reachedAt': null,
          },
        ],
    'myStop':
        myStop ??
        {
          'stopId': 'p3',
          'stopName': 'UNIFOR-MG',
          'fallback': false,
          'alreadyReached': false,
          'etaMinutes': 12,
        },
  });

  setUp(() => service = _MockTripService());

  Future<void> montar(WidgetTester tester, TripStatus estado) async {
    when(() => service.status('l1')).thenAnswer((_) async => estado);
    await tester.pumpWidget(
      MaterialApp(
        home: TripFollowScreen(listId: 'l1', service: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textos(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .join(' | ');

  testWidgets('o tempo nomeia a instituicao do aluno', (tester) async {
    await montar(tester, viagem());

    expect(textos(tester), contains('UNIFOR-MG'));
    expect(textos(tester), contains('12'));
  });

  testWidgets('lista as paradas como checklist', (tester) async {
    await montar(tester, viagem());

    expect(find.text('Rodoviária'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(
      find.byKey(const Key('trip_follow_stop_p1_reached')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('trip_follow_stop_p2_reached')), findsNothing);
  });

  testWidgets('sem tempo calculado a tela omite em vez de mostrar zero', (
    tester,
  ) async {
    await montar(
      tester,
      viagem(
        myStop: {
          'stopId': 'p3',
          'stopName': 'UNIFOR-MG',
          'fallback': false,
          'alreadyReached': false,
          'etaMinutes': null,
        },
      ),
    );

    expect(textos(tester), isNot(contains('0 min')));
    expect(find.byKey(const Key('trip_follow_eta')), findsNothing);
  });

  testWidgets('avisa quando a parada nao e da instituicao dele', (
    tester,
  ) async {
    await montar(
      tester,
      viagem(
        myStop: {
          'stopId': 'p3',
          'stopName': 'IFMG',
          'fallback': true,
          'alreadyReached': false,
          'etaMinutes': 12,
        },
      ),
    );

    expect(
      find.byKey(const Key('trip_follow_fallback_warning')),
      findsOneWidget,
    );
  });

  testWidgets('depois de passar diz que o trecho dele acabou', (tester) async {
    await montar(
      tester,
      viagem(
        myStop: {
          'stopId': 'p1',
          'stopName': 'Rodoviária',
          'fallback': false,
          'alreadyReached': true,
          'etaMinutes': null,
        },
      ),
    );

    expect(
      find.byKey(const Key('trip_follow_already_reached')),
      findsOneWidget,
    );
  });

  testWidgets('trajeto nao iniciado nao inventa progresso', (tester) async {
    await montar(
      tester,
      viagem(
        startedAt: null,
        myStop: {
          'stopId': 'p3',
          'stopName': 'UNIFOR-MG',
          'fallback': false,
          'alreadyReached': false,
          'etaMinutes': null,
        },
      ),
    );

    expect(find.byKey(const Key('trip_follow_not_started')), findsOneWidget);
  });

  testWidgets('sair da tela cancela o polling', (tester) async {
    await montar(tester, viagem());
    clearInteractions(service);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('x'))));
    await tester.pump(const Duration(seconds: 25));
    await tester.pump(const Duration(seconds: 25));

    verifyNever(() => service.status(any()));
  });

  testWidgets('a tela pede o estado de novo depois do intervalo', (
    tester,
  ) async {
    await montar(tester, viagem());
    clearInteractions(service);

    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    verify(() => service.status('l1')).called(1);
  });

  testWidgets('nome de parada longo nao estoura a linha do tempo', (
    tester,
  ) async {
    // Em tela estreita e com nome comprido o Row estourava 4px — o teste
    // falha sozinho se a Text voltar a ficar sem Expanded.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await montar(
      tester,
      viagem(
        myStop: {
          'stopId': 'p3',
          'stopName': 'IFMG — Campus Formiga, Bloco de Engenharia',
          'fallback': false,
          'alreadyReached': false,
          'etaMinutes': 41,
        },
      ),
    );

    expect(find.byKey(const Key('trip_follow_eta')), findsOneWidget);
  });
}
