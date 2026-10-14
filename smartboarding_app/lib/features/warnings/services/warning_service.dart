import '../../../core/services/dio_client.dart';
import '../models/warning_model.dart';

class WarningService {
  final _dio = DioClient.instance;

  Future<({List<WarningModel> items, bool hasMore})> getWarnings({
    String? userId,
    int page = 0,
  }) async {
    final response = await _dio.get(
      '/api/warnings',
      queryParameters: {'userId': ?userId, 'page': page, 'size': 20},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final content = data['content'] as List;
    final totalPages = data['totalPages'] as int;

    return (
      items: content
          .map((e) => WarningModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: page < totalPages - 1,
    );
  }

  Future<List<WarningModel>> getMine() async {
    final response = await _dio.get('/api/warnings/me');
    final List data = response.data['data'] as List;
    return data
        .map((e) => WarningModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/warnings/$id');
  }
}
