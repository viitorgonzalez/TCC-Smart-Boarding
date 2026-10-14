import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

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
      return line
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> snapToRoad(LatLng ponto) async {
    try {
      final response = await _dio.get(
        '$_base/nearest/v1/driving/${ponto.longitude},${ponto.latitude}',
        queryParameters: const {'number': 1},
      );
      final waypoints = (response.data as Map)['waypoints'] as List?;
      if (waypoints == null || waypoints.isEmpty) return null;

      final local = waypoints.first['location'] as List;
      return LatLng((local[1] as num).toDouble(), (local[0] as num).toDouble());
    } catch (_) {
      return null;
    }
  }
}
