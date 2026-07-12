import '../../../core/services/dio_client.dart';
import '../models/route_model.dart';

class RouteService {
  final _dio = DioClient.instance;

  Future<List<RouteModel>> getRoutes() async {
    final response = await _dio.get('/api/routes');
    final List data = response.data['data'] as List;
    return data
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RouteModel> createRoute(String name, String? description) async {
    final response = await _dio.post('/api/routes', data: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RouteModel> updateRoute(
      String id, String name, String? description) async {
    final response = await _dio.patch('/api/routes/$id', data: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    return RouteModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRoute(String id) async {
    await _dio.delete('/api/routes/$id');
  }
}
