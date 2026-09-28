import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/trip/models/trip_status_model.dart';
import 'package:smartboarding_app/features/trip/widgets/finish_trip_dialog.dart';
import 'package:smartboarding_app/features/trip/widgets/next_stop_card.dart';
import 'package:smartboarding_app/features/trip/widgets/trip_progress_card.dart';

TripStatus viagem({
  String? startedAt,
  String? outboundFinishedAt,
  String? finishedAt,
  String leg = 'OUTBOUND',
  List<Map<String, dynamic>> stops = const [],
}) => TripStatus.fromJson({
  'listId': 'l1',
  'routeName': 'Rota Universitária',
  'startedAt': startedAt,
  'outboundFinishedAt': outboundFinishedAt,
  'finishedAt': finishedAt,
  'leg': leg,
  'stops': stops,
});

Map<String, dynamic> parada(String nome, int seq, {String? reachedAt}) => {
  'stopId': 'p$seq',
  'name': nome,
  'sequence': seq,
  'reachedAt': reachedAt,
};

Widget envolve(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  group('TripProgressCard', () {
    testWidgets('mostra quantas paradas ja foram', (tester) async {
      await tester.pumpWidget(
        envolve(
          TripProgressCard(
            trip: viagem(
              startedAt: '2026-09-12T06:00:00',
              stops: [
                parada('Rodoviária', 1, reachedAt: '2026-09-12T06:10:00'),
                parada('Centro', 2),
                parada('Unifor', 3),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1 de 3 paradas'), findsOneWidget);
      expect(find.textContaining('em andamento'), findsOneWidget);
      expect(find.textContaining('06:00'), findsOneWidget);
    });

    testWidgets('singular quando ha uma parada so', (tester) async {
      await tester.pumpWidget(
        envolve(
          TripProgressCard(trip: viagem(stops: [parada('Rodoviária', 1)])),
        ),
      );

      expect(find.text('0 de 1 parada'), findsOneWidget);
    });

    testWidgets('nao iniciado nao inventa horario de saida', (tester) async {
      await tester.pumpWidget(envolve(TripProgressCard(trip: viagem())));

      expect(find.text('Não iniciado'), findsOneWidget);
      expect(find.textContaining('saiu às'), findsNothing);
    });
  });

  group('NextStopCard', () {
    testWidgets('a acao e um alvo grande e unico', (tester) async {
      var marcou = 0;
      await tester.pumpWidget(
        envolve(
          NextStopCard(
            stop: TripStop.fromJson(parada('Centro', 2)),
            onMark: () => marcou++,
          ),
        ),
      );

      expect(find.text('Centro'), findsOneWidget);
      await tester.tap(find.byKey(const Key('trip_mark_button')));
      expect(marcou, 1);
    });

    // Sem travar o botao, o duplo toque vira dois checkpoints e o segundo morre
    // em erro na cara de quem esta dirigindo.
    testWidgets('botao trava enquanto registra', (tester) async {
      var marcou = 0;
      await tester.pumpWidget(
        envolve(
          NextStopCard(
            stop: TripStop.fromJson(parada('Centro', 2)),
            busy: true,
            onMark: () => marcou++,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('trip_mark_button')));
      expect(marcou, 0);
      expect(find.text('Registrando...'), findsOneWidget);
    });
  });

  group('confirmFinishTrip', () {
    Future<bool?> abrir(WidgetTester tester, TripStatus trip) async {
      bool? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async =>
                    resultado = await confirmFinishTrip(context, trip),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return resultado;
    }

    /// O onibus pode pular parada legitimamente, entao o dialogo avisa em vez de
    /// travar -- mas mostra o que ficou pra tras, porque pode ter sido esquecimento.
    testWidgets('lista as paradas nao marcadas e deixa seguir', (tester) async {
      await abrir(
        tester,
        viagem(
          startedAt: '2026-09-12T06:00:00',
          stops: [
            parada('Rodoviária', 1, reachedAt: '2026-09-12T06:10:00'),
            parada('Centro', 2),
            parada('Posto do Zé', 3),
          ],
        ),
      );

      expect(find.text('2 paradas não foram marcadas:'), findsOneWidget);
      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('Posto do Zé'), findsOneWidget);
      // Finalizar continua disponivel: avisa, nao bloqueia.
      expect(find.byKey(const Key('trip_finish_confirm')), findsOneWidget);
    });

    testWidgets('singular com uma pendente so', (tester) async {
      await abrir(
        tester,
        viagem(startedAt: '2026-09-12T06:00:00', stops: [parada('Centro', 1)]),
      );

      expect(find.text('1 parada não foi marcada:'), findsOneWidget);
    });

    testWidgets('sem pendencia diz que esta tudo marcado', (tester) async {
      await abrir(
        tester,
        viagem(
          startedAt: '2026-09-12T06:00:00',
          stops: [parada('Rodoviária', 1, reachedAt: '2026-09-12T06:10:00')],
        ),
      );

      expect(find.text('Todas as paradas foram marcadas.'), findsOneWidget);
      expect(find.textContaining('não foi marcada'), findsNothing);
    });

    testWidgets('avisa que a rota inteira e notificada', (tester) async {
      await abrir(tester, viagem(startedAt: '2026-09-12T06:00:00'));

      expect(
        find.text('Todos os alunos da rota são avisados.'),
        findsOneWidget,
      );
    });
  });

  group('perna do trajeto', () {
    testWidgets('ida em andamento diz que e a ida', (tester) async {
      await tester.pumpWidget(
        envolve(
          TripProgressCard(trip: viagem(startedAt: '2026-09-12T06:00:00')),
        ),
      );

      expect(find.textContaining('Ida em andamento'), findsOneWidget);
    });

    // A perna muda o que o admin ve na lista (as paradas invertem); dizer qual e
    // evita a duvida de "por que a ordem mudou?".
    testWidgets('volta em andamento diz que e a volta', (tester) async {
      await tester.pumpWidget(
        envolve(
          TripProgressCard(
            trip: viagem(
              startedAt: '2026-09-12T06:00:00',
              outboundFinishedAt: '2026-09-12T07:00:00',
              leg: 'RETURN',
            ),
          ),
        ),
      );

      expect(find.textContaining('Volta em andamento'), findsOneWidget);
    });

    testWidgets('encerrado nao fala de perna', (tester) async {
      await tester.pumpWidget(
        envolve(
          TripProgressCard(
            trip: viagem(
              startedAt: '2026-09-12T06:00:00',
              outboundFinishedAt: '2026-09-12T07:00:00',
              finishedAt: '2026-09-12T18:30:00',
              leg: 'RETURN',
            ),
          ),
        ),
      );

      expect(find.textContaining('Concluído'), findsOneWidget);
      expect(find.textContaining('em andamento'), findsNothing);
    });

    // Resposta antiga sem o campo nao pode derrubar a tela.
    testWidgets('sem o campo leg assume ida', (tester) async {
      final semLeg = TripStatus.fromJson({
        'listId': 'l1',
        'routeName': 'Rota Universitária',
        'startedAt': '2026-09-12T06:00:00',
        'stops': [],
      });

      expect(semLeg.onReturn, isFalse);
      await tester.pumpWidget(envolve(TripProgressCard(trip: semLeg)));
      expect(find.textContaining('Ida em andamento'), findsOneWidget);
    });
  });

  group('qual parada o botao marca', () {
    /// O botão é único e sempre o mesmo widget. Se ele marcasse a primeira em
    /// vez da atual, o admin registraria a rodoviária de novo a cada toque e o
    /// trajeto nunca sairia dela.
    test('a parada atual e a primeira ainda nao alcancada', () {
      final trip = viagem(
        startedAt: '2026-09-25T07:00:00',
        stops: [
          parada('Rodoviária', 1, reachedAt: '2026-09-25T07:05:00'),
          parada('Centro', 2),
          parada('UNIFOR-MG', 3),
        ],
      );

      expect(trip.current!.name, 'Centro');
      expect(trip.current!.stopId, 'p2');
    });

    /// Todas marcadas: nenhuma atual, e a tela mostra "tudo marcado" em vez de
    /// um botão que não tem o que fazer.
    test('sem pendente nao ha parada atual', () {
      final trip = viagem(
        startedAt: '2026-09-25T07:00:00',
        stops: [
          parada('Rodoviária', 1, reachedAt: '2026-09-25T07:05:00'),
          parada('Centro', 2, reachedAt: '2026-09-25T07:20:00'),
        ],
      );

      expect(trip.current, isNull);
    });

    /// Trajeto não iniciado não tem parada atual: marcar chegada antes de sair
    /// registraria uma viagem que não aconteceu.
    test('nao iniciado nao tem parada atual', () {
      final trip = viagem(stops: [parada('Rodoviária', 1)]);

      expect(trip.current, isNull);
    });

    /// A última parada mantém o botão de marcar: ela é uma chegada como as
    /// outras, e trocá-lo por "Encerrar" perderia o registro de que o ônibus
    /// chegou ali. Encerrar é o passo seguinte, não o mesmo.
    testWidgets('a ultima parada ainda e marcada, nao encerrada', (
      tester,
    ) async {
      final trip = viagem(
        startedAt: '2026-09-25T07:00:00',
        stops: [
          parada('Rodoviária', 1, reachedAt: '2026-09-25T07:05:00'),
          parada('UNIFOR-MG', 2),
        ],
      );

      await tester.pumpWidget(
        envolve(NextStopCard(stop: trip.current!, onMark: () {})),
      );

      expect(find.text('Cheguei aqui'), findsOneWidget);
      expect(find.text('UNIFOR-MG'), findsOneWidget);
    });
  });
}
