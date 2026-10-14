import '../../../core/services/dio_client.dart';
import '../models/address_model.dart';
import '../models/profile_update_model.dart';

class ProfileService {
  final _dio = DioClient.instance;

  Future<ProfileUpdate> requestUpdate({
    String? fullName,
    String? institutionId,
    String? birthDate,
    String? phone,
    String? course,
    Address? address,
  }) async {
    final response = await _dio.post(
      '/api/me/profile-requests',
      data: {
        'fullName': ?fullName,
        'institutionId': ?institutionId,
        'birthDate': ?birthDate,
        'phone': ?phone,
        'course': ?course,
        'zipCode': ?address?.zipCode,
        'street': ?address?.street,
        'neighborhood': ?address?.neighborhood,
        'city': ?address?.city,
        'state': ?address?.state,
        'streetNumber': ?address?.streetNumber,
        'complement': ?address?.complement,
      },
    );
    return ProfileUpdate.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

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

  Future<List<ProfileUpdate>> allRequests({String? status}) async {
    final response = await _dio.get(
      '/api/profile-requests/all',
      queryParameters: {'status': ?status},
    );
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

  Future<ProfileUpdate?> myLatest() async {
    final response = await _dio.get('/api/me/profile-requests/latest');
    final data = response.data['data'];
    return data == null
        ? null
        : ProfileUpdate.fromJson(data as Map<String, dynamic>);
  }

  Future<Address> updateAddress(Address endereco) async {
    final response = await _dio.put('/api/me/address', data: endereco.toJson());
    return Address.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> updateOwnProfile({String? phone, String? course}) async {
    await _dio.put(
      '/api/me/profile',
      data: {'phone': ?phone, 'course': ?course},
    );
  }

  Future<Me> me() async {
    final response = await _dio.get('/api/me');
    return Me.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> setLocalPassword(String password) async {
    await _dio.post('/api/me/password', data: {'password': password});
  }

  Future<void> changePassword(String current, String novaSenha) async {
    await _dio.put(
      '/api/me/password',
      data: {'currentPassword': current, 'newPassword': novaSenha},
    );
  }

  Future<void> requestEmailChange(String newEmail) async {
    await _dio.post('/api/me/email/request', data: {'newEmail': newEmail});
  }

  Future<void> confirmEmailChange(String code) async {
    await _dio.post('/api/me/email/confirm', data: {'code': code});
  }

  Future<List<String>> myInstitutions() async {
    final response = await _dio.get('/api/me/institutions');
    return (response.data['data'] as List).map((e) => e as String).toList();
  }

  Future<void> addInstitution(String institutionId) async {
    await _dio.post('/api/me/institutions/$institutionId');
  }

  Future<void> removeInstitution(String institutionId) async {
    await _dio.delete('/api/me/institutions/$institutionId');
  }
}
