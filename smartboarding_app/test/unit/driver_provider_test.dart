import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/driver/providers/driver_provider.dart';
import 'package:smartboarding_app/features/driver/services/driver_service.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';

class _MockListService extends Mock implements ListService {}

class _MockDriverService extends Mock implements DriverService {}

DailyList _list(String id) => DailyList(
      id: id,
      routeId: 'r1',
      routeName: 'Rota Principal',
      date: '2026-07-11',
      status: 'CLOSED',
      totalEntries: 12,
    );

void main() {
  late _MockListService listService;
  late _MockDriverService driverService;
  late DriverProvider provider;

  setUp(() {
    listService = _MockListService();
    driverService = _MockDriverService();
    provider = DriverProvider(listService, driverService);
  });

  test('load popula listas e seleciona a primeira', () async {
    when(() => listService.getTodayLists())
        .thenAnswer((_) async => [_list('a'), _list('b')]);

    await provider.load();

    expect(provider.state, isA<AsyncData<List<DailyList>>>());
    expect(provider.selected?.id, 'a');
  });

  test('sendDeparture usa a lista selecionada e retorna notified', () async {
    when(() => listService.getTodayLists())
        .thenAnswer((_) async => [_list('a')]);
    when(() => driverService.sendDeparture('a', body: 'saindo'))
        .thenAnswer((_) async => 7);
    await provider.load();

    final notified = await provider.sendDeparture('saindo');

    expect(notified, 7);
    verify(() => driverService.sendDeparture('a', body: 'saindo')).called(1);
  });

  test('sendDeparture sem seleção lança StateError', () async {
    when(() => listService.getTodayLists()).thenAnswer((_) async => []);
    await provider.load();

    expect(() => provider.sendDeparture('x'), throwsStateError);
  });
}
