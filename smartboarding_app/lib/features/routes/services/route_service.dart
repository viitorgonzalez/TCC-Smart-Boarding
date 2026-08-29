import '../../../core/services/dio_client.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';

class RouteService {
  final _dio = DioClient.instance;

  Future<List<StopModel>> getStops(String routeId) async {
    final response = await _dio.get('/api/routes/$routeId/stops');
    final List data = response.data['data'] as List;
    return data
        .map((e) => StopModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RouteModel>> getRoutes() async {
    final response = await _dio.get('/api/routes');
    final List data = response.data['data'] as List;
    return data
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RouteModel> createRoute(String name, String? description) async {
    final response = await _dio.post(
      '/api/routes',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RouteModel> updateRoute(
    String id,
    String name,
    String? description,
  ) async {
    final response = await _dio.patch(
      '/api/routes/$id',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Endpoint separado do update comum: mexer na janela da lista exige [reason]
  /// e dispara aviso pra rota inteira.
  Future<RouteModel> updateSchedule(
    String id, {
    required String openTime,
    required String closeTime,
    required String reason,
  }) async {
    final response = await _dio.patch(
      '/api/routes/$id/schedule',
      data: {'openTime': openTime, 'closeTime': closeTime, 'reason': reason},
    );
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// [sequence] posiciona a parada no trajeto empurrando as seguintes; nulo
  /// acrescenta no fim.
  Future<StopModel> addStop(
    String routeId,
    String name, {
    double? latitude,
    double? longitude,
    int? sequence,
  }) async {
    final response = await _dio.post(
      '/api/routes/$routeId/stops',
      data: {
        'name': name,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'sequence': ?sequence,
      },
    );
    return StopModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// [sequence] posiciona a parada no trajeto; nulo acrescenta no fim.
  Future<void> updateStop(
    String routeId,
    String stopId, {
    String? name,
    double? latitude,
    double? longitude,
  }) async {
    await _dio.patch(
      '/api/routes/$routeId/stops/$stopId',
      data: {'name': ?name, 'latitude': ?latitude, 'longitude': ?longitude},
    );
  }

  Future<void> deleteStop(String routeId, String stopId) async {
    await _dio.delete('/api/routes/$routeId/stops/$stopId');
  }

  Future<List<VehicleModel>> getVehicles(String routeId) async {
    final response = await _dio.get('/api/routes/$routeId/vehicles');
    final List data = response.data['data'] as List;
    return data
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel> addVehicle(
    String routeId,
    String label,
    int capacity,
  ) async {
    final response = await _dio.post(
      '/api/routes/$routeId/vehicles',
      data: {'label': label, 'capacity': capacity},
    );
    return VehicleModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String routeId, String vehicleId) async {
    await _dio.delete('/api/routes/$routeId/vehicles/$vehicleId');
  }

  Future<void> deleteRoute(String id) async {
    await _dio.delete('/api/routes/$id');
  }
}
