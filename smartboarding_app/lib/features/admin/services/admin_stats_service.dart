import '../../../core/services/dio_client.dart';
import '../models/admin_stats_model.dart';

class AdminStatsService {
  final _dio = DioClient.instance;

  Future<AdminStats> getStats() async {
    final response = await _dio.get('/api/admin/stats');
    return AdminStats.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
