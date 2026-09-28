import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/institutions/models/institution_model.dart';
import 'package:smartboarding_app/features/routes/models/map_stop.dart';
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
    ).thenAnswer((_) async => StopModel(id: 's1', name: 'Nova', sequence: 1));
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

  // ─── Vínculo com a instituição (o bug do is_main_point) ───────────────────

  const unifor = InstitutionModel(id: 'i1', name: 'UNIFOR-MG', routeId: 'r1');
  const mapStop = MapStop(
    id: 's1',
    name: 'Campus Unifor',
    latitude: -20.46,
    longitude: -45.42,
    sequence: 1,
  );
  final parada = StopModel(
    id: 's1',
    name: 'Campus Unifor',
    sequence: 1,
    latitude: -20.46,
    longitude: -45.42,
  );

  Future<void> montarComParada(
    WidgetTester tester, {
    List<InstitutionModel> instituicoes = const [unifor],
  }) async {
    when(() => road.snapToRoad(any())).thenAnswer((_) async => null);
    when(
      () => service.setStopInstitution(
        any(),
        any(),
        institutionId: any(named: 'institutionId'),
        mainPoint: any(named: 'mainPoint'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteStopsEditor(
            key: chave,
            routeId: 'r1',
            stops: [parada],
            institutions: instituicoes,
            service: service,
            roadService: road,
            run: (acao, _) => acao(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Sem este caminho, parada criada pelo app nunca vira ponto principal — e o
  /// trajeto recusa todo checkpoint nela com STOP_NOT_MAIN_POINT.
  testWidgets('admin vincula a parada a uma instituicao', (tester) async {
    await montarComParada(tester);

    unawaited(chave.currentState!.onTapStop(mapStop));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stop_link_institution')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UNIFOR-MG'));
    await tester.pumpAndSettle();

    verify(
      () => service.setStopInstitution(
        'r1',
        's1',
        institutionId: 'i1',
        mainPoint: any(named: 'mainPoint'),
      ),
    ).called(1);
  });

  /// "Nenhuma" é resposta, não desistência: é assim que se desfaz o vínculo.
  /// Confundi-la com "fechou o menu" deixaria a parada presa à instituição.
  testWidgets('escolher "nenhuma" desfaz o vinculo', (tester) async {
    await montarComParada(tester);

    unawaited(chave.currentState!.onTapStop(mapStop));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stop_link_institution')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stop_institution_none')));
    await tester.pumpAndSettle();

    verify(
      () => service.setStopInstitution(
        'r1',
        's1',
        institutionId: null,
        mainPoint: any(named: 'mainPoint'),
      ),
    ).called(1);
  });

  /// Rota sem instituição nenhuma não tem o que oferecer: o menu seria um beco.
  testWidgets('sem instituicao na rota a acao nem aparece', (tester) async {
    await montarComParada(tester, instituicoes: const []);

    unawaited(chave.currentState!.onTapStop(mapStop));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stop_link_institution')), findsNothing);
  });
}
