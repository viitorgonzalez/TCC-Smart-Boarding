import '../../../core/services/dio_client.dart';
import '../models/warning_model.dart';

class WarningService {
  final _dio = DioClient.instance;

  /// [userId] nulo traz todas — visão do admin.
  Future<List<WarningModel>> getWarnings({String? userId}) async {
    final response = await _dio.get(
      '/api/warnings',
      queryParameters: {'userId': ?userId},
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => WarningModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// O aluno não passa id: o backend resolve pelo token.
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
