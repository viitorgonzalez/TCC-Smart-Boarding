import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/trip/models/trip_status_model.dart';
import 'package:smartboarding_app/features/trip/widgets/finish_trip_dialog.dart';
import 'package:smartboarding_app/features/trip/widgets/next_stop_card.dart';
import 'package:smartboarding_app/features/trip/widgets/trip_map.dart';
import 'package:smartboarding_app/features/trip/widgets/trip_progress_card.dart';
import 'package:smartboarding_app/features/routes/services/road_route_service.dart';
import 'package:smartboarding_app/features/routes/widgets/stop_pin.dart';
import 'package:dio/dio.dart';

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

Map<String, dynamic> parada(
  String nome,
  int seq, {
  String? reachedAt,
  double? lat,
  double? lng,
}) => {
  'stopId': 'p$seq',
  'name': nome,
  'sequence': seq,
  'reachedAt': reachedAt,
  'latitude': lat,
  'longitude': lng,
};

Widget envolve(Widget w) => MaterialApp(home: Scaffold(body: w));

/// OSRM que responde na hora: sem isto o mapa deixa um timer de rede pendente
/// e o teste falha por causa da chamada, não do que ele quer verificar.
class _OsrmAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, _, _) async =>
      ResponseBody.fromString(
        '{"routes":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

RoadRouteService osrmFalso() =>
    RoadRouteService(dio: Dio()..httpClientAdapter = _OsrmAdapter());

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

    test('nao iniciado nao tem parada atual', () {
      final trip = viagem(stops: [parada('Rodoviária', 1)]);

      expect(trip.current, isNull);
    });

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

  group('TripMap', () {
    testWidgets('desenha o mapa quando ha parada com coordenada', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolve(
          TripMap(
            roadRoute: osrmFalso(),
            trip: viagem(
              stops: [
                parada('Rodoviária', 1, lat: -20.46, lng: -45.42),
                parada('Unifor', 2, lat: -20.47, lng: -45.43),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_map')), findsOneWidget);
    });

    testWidgets('sem coordenada nenhuma o mapa nao aparece', (tester) async {
      await tester.pumpWidget(
        envolve(
          TripMap(
            trip: viagem(stops: [parada('Rodoviária', 1), parada('Unifor', 2)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_map')), findsNothing);
    });

    testWidgets('ignora so a parada sem ponto, nao o mapa inteiro', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolve(
          TripMap(
            roadRoute: osrmFalso(),
            trip: viagem(
              stops: [
                parada('Rodoviária', 1, lat: -20.46, lng: -45.42),
                parada('Sem ponto', 2),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_map')), findsOneWidget);
    });

    testWidgets('a parada ja alcancada vem marcada como alcancada', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolve(
          TripMap(
            roadRoute: osrmFalso(),
            trip: viagem(
              startedAt: '2026-09-12T06:00:00',
              stops: [
                parada(
                  'Rodoviária',
                  1,
                  reachedAt: '2026-09-12T06:10:00',
                  lat: -20.46,
                  lng: -45.42,
                ),
                parada('Unifor', 2, lat: -20.47, lng: -45.43),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pinos = tester
          .widgetList<StopPin>(find.byType(StopPin))
          .map((p) => (p.stop.name, p.stop.reached))
          .toList();
      expect(pinos, contains(('Rodoviária', true)));
      expect(pinos, contains(('Unifor', false)));
    });
  });
}
