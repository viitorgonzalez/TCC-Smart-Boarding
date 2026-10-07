import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/routes/services/road_route_service.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late RoadRouteService service;

  setUp(() {
    dio = _MockDio();
    service = RoadRouteService(dio: dio);
  });

  void responde(Object? corpo) {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        data: corpo,
        requestOptions: RequestOptions(path: ''),
      ),
    );
  }

  test('devolve a coordenada grudada na via', () async {
    responde({
      'code': 'Ok',
      'waypoints': [
        {
          'location': [-45.4267, -20.4644],
          'name': 'Avenida Doutor Arnaldo de Senna',
        },
      ],
    });

    final grudado = await service.snapToRoad(const LatLng(-20.4650, -45.4270));

    expect(grudado!.latitude, closeTo(-20.4644, 1e-6));
    expect(grudado.longitude, closeTo(-45.4267, 1e-6));
  });

  test('nao inverte latitude com longitude', () async {
    responde({
      'code': 'Ok',
      'waypoints': [
        {
          'location': [-45.0, -20.0],
        },
      ],
    });

    final grudado = await service.snapToRoad(const LatLng(-20.0, -45.0));

    expect(grudado!.latitude, -20.0);
    expect(grudado.longitude, -45.0);
  });

  test('servico fora do ar devolve nulo', () async {
    when(
      () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(await service.snapToRoad(const LatLng(-20.0, -45.0)), isNull);
  });

  test('resposta sem waypoint devolve nulo', () async {
    responde({'code': 'Ok', 'waypoints': []});

    expect(await service.snapToRoad(const LatLng(-20.0, -45.0)), isNull);
  });

  test('corpo inesperado devolve nulo em vez de estourar', () async {
    responde('<html>erro</html>');

    expect(await service.snapToRoad(const LatLng(-20.0, -45.0)), isNull);
  });
}
