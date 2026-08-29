import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Caminho por ruas via OSRM público — gratuito e sem chave.
///
/// ⚠️ É o servidor de demonstração do projeto: sem SLA e com limite de uso.
/// Deploy real deve apontar pra instância própria ou serviço com contrato.
class RoadRouteService {
  static const _base = 'https://router.project-osrm.org';

  final Dio _dio = Dio(
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
}
