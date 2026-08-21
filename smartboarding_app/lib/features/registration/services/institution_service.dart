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

  Future<void> createInstitution(
    String name,
    String? address,
    double? latitude,
    double? longitude,
  ) async {
    await _dio.post(
      '/api/institutions',
      data: {
        'name': name,
        if (address?.isNotEmpty ?? false) 'address': address!,
        if (latitude case != null) 'latitude': latitude,
        if (longitude case != null) 'longitude': longitude,
      },
    );
  }
}
