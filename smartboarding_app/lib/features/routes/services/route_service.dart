import '../../../core/services/dio_client.dart';
import '../models/invite_code_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';

class RouteService {
  final _dio = DioClient.instance;

  Future<List<InviteCode>> getInviteCodes(String routeId) async {
    final response = await _dio.get('/api/routes/$routeId/invite-codes');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => InviteCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InviteCode>> getAllInviteCodes() async {
    final response = await _dio.get('/api/invite-codes');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => InviteCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> archiveInviteCodes(List<String> codeIds) async {
    final response = await _dio.delete(
      '/api/invite-codes',
      data: {'codeIds': codeIds},
    );
    return (response.data['data']?['archived'] as num?)?.toInt() ?? 0;
  }

  Future<InviteCode> generateInviteCode(
    String routeId, {
    DateTime? expiresAt,
    String? institutionId,
  }) async {
    final response = await _dio.post(
      '/api/routes/$routeId/invite-codes',
      data: {
        'expiresAt': ?expiresAt?.toIso8601String(),
        'institutionId': ?institutionId,
      },
    );
    return InviteCode.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> revokeInviteCode(String routeId, String codeId) async {
    await _dio.delete('/api/routes/$routeId/invite-codes/$codeId');
  }

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
    String? description, {
    bool? admitsNoInstitution,
  }) async {
    final response = await _dio.patch(
      '/api/routes/$id',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'admitsNoInstitution': ?admitsNoInstitution,
      },
    );
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

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

  Future<void> setStopInstitution(
    String routeId,
    String stopId, {
    String? institutionId,
    bool mainPoint = false,
  }) async {
    await _dio.patch(
      '/api/routes/$routeId/stops/$stopId',
      data: {'institutionId': institutionId, 'mainPoint': mainPoint},
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
