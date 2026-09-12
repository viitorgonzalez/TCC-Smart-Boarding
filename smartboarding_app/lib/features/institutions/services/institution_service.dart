import '../../../core/services/dio_client.dart';
import '../models/institution_model.dart';

class InstitutionService {
  final _dio = DioClient.instance;

  Future<List<InstitutionModel>> getInstitutions() async {
    final response = await _dio.get('/api/institutions');
    final List data = response.data['data'] as List;
    return data
        .map((e) => InstitutionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [routeId] já vincula a instituição à rota que a atende (RN15).
  Future<void> createInstitution(
    String name, {
    String? address,
    double? latitude,
    double? longitude,
    String? routeId,
  }) async {
    await _dio.post(
      '/api/institutions',
      data: {
        'name': name,
        'address': ?address,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'routeId': ?routeId,
      },
    );
  }

  /// routeId nulo desvincula. O backend recusa trocar de rota ativa sem
  /// desvincular antes (RN15).
  Future<void> linkRoute(String institutionId, String? routeId) async {
    await _dio.patch(
      '/api/institutions/$institutionId/route',
      data: {'routeId': routeId},
    );
  }

  Future<void> updateInstitution(
    String id, {
    String? name,
    String? address,
  }) async {
    await _dio.patch(
      '/api/institutions/$id',
      data: {'name': ?name, 'address': ?address},
    );
  }

  /// O backend recusa se houver aluno vinculado (a rota dele sai daqui).
  Future<void> deleteInstitution(String id) async {
    await _dio.delete('/api/institutions/$id');
  }
}
