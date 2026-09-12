import '../../../core/services/dio_client.dart';
import '../models/profile_update_model.dart';

class ProfileService {
  final _dio = DioClient.instance;

  /// Manda só o que mudou: campo ausente significa "não pedi mudança nele".
  Future<ProfileUpdate> requestUpdate({
    String? fullName,
    String? phone,
    String? address,
    String? course,
    String? institutionId,
    String? birthDate,
  }) async {
    final response = await _dio.post(
      '/api/me/profile-requests',
      data: {
        'fullName': ?fullName,
        'phone': ?phone,
        'address': ?address,
        'course': ?course,
        'institutionId': ?institutionId,
        'birthDate': ?birthDate,
      },
    );
    return ProfileUpdate.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Nulo quando não há pedido em análise.
  Future<ProfileUpdate?> myPending() async {
    final response = await _dio.get('/api/me/profile-requests/pending');
    final data = response.data['data'];
    return data == null
        ? null
        : ProfileUpdate.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProfileUpdate>> pending() async {
    final response = await _dio.get('/api/profile-requests');
    final List data = response.data['data'] as List;
    return data
        .map((e) => ProfileUpdate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve(String id) async {
    await _dio.post('/api/profile-requests/$id/approve');
  }

  Future<void> reject(String id, String reason) async {
    await _dio.post(
      '/api/profile-requests/$id/reject',
      data: {'reason': reason},
    );
  }
}
