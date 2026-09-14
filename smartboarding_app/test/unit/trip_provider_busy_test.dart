import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/trip/providers/trip_provider.dart';
import 'package:smartboarding_app/features/trip/services/trip_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;

  Map<String, dynamic> status() => {
    'data': {
      'listId': 'l1',
      'routeName': 'Rota Universitária',
      'startedAt': '2026-09-12T06:00:00',
      'finishedAt': null,
      'stops': [
        {
          'stopId': 'p1',
          'name': 'Rodoviária',
          'sequence': 1,
          'reachedAt': null,
        },
      ],
    },
  };

  setUp(() async {
    http = await installFakeHttp();
    http.always(body: status());
  });

  test('busy fica falso fora de acao', () async {
    final p = TripProvider(TripService(), 'l1');

    expect(p.busy, isFalse);
    await p.load();
    expect(p.busy, isFalse);
  });

  // Quem esta dirigindo toca com pressa. Sem a trava, o segundo toque vira um
  // segundo checkpoint e morre em erro na cara dele.
  test('segundo toque durante a acao e ignorado', () async {
    final p = TripProvider(TripService(), 'l1');

    final primeira = p.checkpoint('p1');
    final segunda = p.checkpoint('p1');
    await Future.wait([primeira, segunda]);

    expect(http.requests.where((r) => r.path.contains('checkpoint')).length, 1);
  });

  test('busy volta a falso mesmo quando a acao falha', () async {
    http.always(status: 500, body: {'error': 'boom'});
    final p = TripProvider(TripService(), 'l1');

    await p.checkpoint('p1');

    // Travar pra sempre apos um erro deixaria o trajeto inoperante ate reabrir
    // a tela.
    expect(p.busy, isFalse);
  });

  test('apos a acao terminar, a proxima passa', () async {
    final p = TripProvider(TripService(), 'l1');

    await p.checkpoint('p1');
    await p.checkpoint('p1');

    expect(http.requests.where((r) => r.path.contains('checkpoint')).length, 2);
  });
}
