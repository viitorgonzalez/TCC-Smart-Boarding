import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/trip/models/trip_status_model.dart';
import 'package:smartboarding_app/features/trip/providers/trip_provider.dart';
import 'package:smartboarding_app/features/trip/services/trip_service.dart';

class _MockTripService extends Mock implements TripService {}

void main() {
  late _MockTripService service;
  late TripProvider provider;

  const listId = 'lista-1';

  TripStatus status({
    String? startedAt,
    String? finishedAt,
    bool reached = false,
  }) => TripStatus(
    listId: listId,
    routeName: 'Rota Universitária de Formiga',
    startedAt: startedAt,
    finishedAt: finishedAt,
    stops: [
      TripStop(
        stopId: 'parada-1',
        name: 'Rodoviária de Pimenta',
        sequence: 1,
        reachedAt: reached ? '2026-09-08T06:40:00' : null,
      ),
    ],
  );

  setUp(() {
    service = _MockTripService();
    provider = TripProvider(service, listId);
  });

  test('load traz o estado do trajeto', () async {
    when(() => service.status(listId)).thenAnswer((_) async => status());

    await provider.load();

    expect((provider.state as AsyncData<TripStatus>).value.notStarted, isTrue);
  });

  test('start marca o trajeto como em curso', () async {
    when(
      () => service.start(listId),
    ).thenAnswer((_) async => status(startedAt: '2026-09-08T06:30:00'));

    await provider.start();

    expect((provider.state as AsyncData<TripStatus>).value.inProgress, isTrue);
  });

  test('checkpoint marca a parada como alcançada', () async {
    when(() => service.checkpoint(listId, 'parada-1')).thenAnswer(
      (_) async => status(startedAt: '2026-09-08T06:30:00', reached: true),
    );

    await provider.checkpoint('parada-1');

    final value = (provider.state as AsyncData<TripStatus>).value;
    expect(value.stops.first.reached, isTrue);
  });

  test('a parada atual é a primeira ainda não alcançada', () {
    final trip = status(startedAt: '2026-09-08T06:30:00');

    expect(trip.current?.stopId, 'parada-1');
  });

  test('trajeto não iniciado não tem parada atual', () {
    expect(status().current, isNull);
  });

  test('erro do backend vira AsyncError sem derrubar a tela', () async {
    when(
      () => service.start(listId),
    ).thenThrow(Exception('TRIP_ALREADY_STARTED'));

    await provider.start();

    expect(provider.state, isA<AsyncError<TripStatus>>());
  });
}
