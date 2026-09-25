import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/routes/models/stop_model.dart';
import 'package:smartboarding_app/features/routes/services/road_route_service.dart';
import 'package:smartboarding_app/features/routes/services/route_service.dart';
import 'package:smartboarding_app/features/routes/widgets/route_stops_editor.dart';

class _MockRoad extends Mock implements RoadRouteService {}

class _MockRouteService extends Mock implements RouteService {}

void main() {
  late _MockRoad road;
  late _MockRouteService service;
  late GlobalKey<RouteStopsEditorState> chave;

  const tocado = LatLng(-20.4650, -45.4270);
  const naVia = LatLng(-20.4644, -45.4267);

  setUpAll(() => registerFallbackValue(const LatLng(0, 0)));

  setUp(() {
    road = _MockRoad();
    service = _MockRouteService();
    chave = GlobalKey<RouteStopsEditorState>();
    when(
      () => service.addStop(
        any(),
        any(),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        sequence: any(named: 'sequence'),
      ),
    ).thenAnswer(
      (_) async => StopModel(id: 's1', name: 'Nova', sequence: 1),
    );
  });

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteStopsEditor(
            key: chave,
            routeId: 'r1',
            stops: const [],
            service: service,
            roadService: road,
            run: (acao, _) => acao(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// O pino ficava onde o dedo encostou: no meio do quarteirão ou no lado
  /// errado da via. O aluno via uma parada que não é onde o ônibus encosta.
  testWidgets('a parada nasce na coordenada corrigida, nao na do toque', (
    tester,
  ) async {
    when(() => road.snapToRoad(any())).thenAnswer((_) async => naVia);
    await montar(tester);

    final futuro = chave.currentState!.onMapPoint(tocado);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Rodoviária');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await futuro;

    verify(
      () => service.addStop(
        'r1',
        'Rodoviária',
        latitude: naVia.latitude,
        longitude: naVia.longitude,
        sequence: any(named: 'sequence'),
      ),
    ).called(1);
  });

  /// OSRM público não tem SLA. Uma parada no lugar aproximado é melhor que
  /// nenhuma parada.
  testWidgets('servico fora do ar ainda cria a parada, no ponto do toque', (
    tester,
  ) async {
    when(() => road.snapToRoad(any())).thenAnswer((_) async => null);
    await montar(tester);

    final futuro = chave.currentState!.onMapPoint(tocado);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Centro');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await futuro;

    verify(
      () => service.addStop(
        'r1',
        'Centro',
        latitude: tocado.latitude,
        longitude: tocado.longitude,
        sequence: any(named: 'sequence'),
      ),
    ).called(1);
  });
}
