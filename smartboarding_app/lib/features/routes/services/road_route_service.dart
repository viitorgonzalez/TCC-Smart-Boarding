import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Caminho por ruas via OSRM público — gratuito e sem chave.
///
/// ⚠️ É o servidor de demonstração do projeto: sem SLA e com limite de uso.
/// Deploy real deve apontar pra instância própria ou serviço com contrato.
class RoadRouteService {
  static const _base = 'https://router.project-osrm.org';

  final Dio _dio;

  RoadRouteService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  /// Null quando o serviço não responde — quem chama cai na linha reta.
  Future<List<LatLng>?> pathThrough(List<LatLng> stops) async {
    if (stops.length < 2) return null;

    final coords = stops.map((p) => '${p.longitude},${p.latitude}').join(';');
    try {
      final response = await _dio.get(
        '$_base/route/v1/driving/$coords',
        queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
      );
      final routes = response.data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final line = routes.first['geometry']['coordinates'] as List;
      // GeoJSON vem como [longitude, latitude] — invertido em relação ao LatLng.
      return line
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Gruda um ponto na via mais próxima.
  ///
  /// O admin cria a parada tocando o mapa, e o toque cai no meio do quarteirão
  /// ou no lado errado da rua. O OSRM já fazia isso internamente pra calcular
  /// o trajeto, mas o **pino** continuava onde o dedo encostou — o desenho e a
  /// realidade divergiam, e o aluno via uma parada que não é onde o ônibus
  /// encosta.
  ///
  /// Null quando o serviço não responde: quem chama guarda o ponto do toque,
  /// porque uma parada no lugar aproximado é melhor que nenhuma parada.
  Future<LatLng?> snapToRoad(LatLng ponto) async {
    try {
      final response = await _dio.get(
        '$_base/nearest/v1/driving/${ponto.longitude},${ponto.latitude}',
        queryParameters: const {'number': 1},
      );
      final waypoints = (response.data as Map)['waypoints'] as List?;
      if (waypoints == null || waypoints.isEmpty) return null;

      // [longitude, latitude] — invertido em relação ao LatLng. Trocar a ordem
      // põe a parada em outro continente sem erro nenhum.
      final local = waypoints.first['location'] as List;
      return LatLng((local[1] as num).toDouble(), (local[0] as num).toDouble());
    } catch (_) {
      return null;
    }
  }
}
