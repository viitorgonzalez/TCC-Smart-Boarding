import '../../../core/services/dio_client.dart';
import '../models/trip_status_model.dart';

class TripService {
  final _dio = DioClient.instance;

  Future<TripStatus> status(String listId) async {
    final response = await _dio.get('/api/trip/$listId');
    return TripStatus.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TripStatus> start(String listId) async {
    final response = await _dio.post('/api/trip/$listId/start');
    return TripStatus.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TripStatus> checkpoint(String listId, String stopId) async {
    final response = await _dio.post('/api/trip/$listId/checkpoint/$stopId');
    return TripStatus.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TripStatus> finish(String listId) async {
    final response = await _dio.post('/api/trip/$listId/finish');
    return TripStatus.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
