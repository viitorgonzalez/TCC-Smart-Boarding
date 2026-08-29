import '../../../core/services/dio_client.dart';
import '../models/invite_info_model.dart';
import '../models/registration_request_model.dart';

class RegistrationService {
  final _dio = DioClient.instance;

  Future<void> generateInvite(String email) async {
    await _dio.post('/api/registration/invite', data: {'email': email});
  }

  Future<InviteInfoModel> getInvite(String token) async {
    final response = await _dio.get('/api/registration/invite/$token');
    return InviteInfoModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> resendCode(String email) async {
    await _dio.post('/api/registration/resend-code', data: {'email': email});
  }

  Future<String> verifyCode(String email, String code) async {
    final response = await _dio.post(
      '/api/registration/verify-code',
      data: {'email': email, 'code': code},
    );
    return response.data['data']['token'] as String;
  }

  Future<void> submit({
    required String token,
    required String fullName,
    required String password,
    required String institutionId,
    String? course,
    String? phone,
    String? address,
    String? birthDate,
  }) async {
    await _dio.post(
      '/api/registration/$token/submit',
      data: {
        'fullName': fullName,
        'password': password,
        'institutionId': institutionId,
        if (course?.isNotEmpty ?? false) 'course': course!,
        if (phone?.isNotEmpty ?? false) 'phone': phone!,
        if (address?.isNotEmpty ?? false) 'address': address!,
        if (birthDate case != null) 'birthDate': birthDate,
      },
    );
  }

  Future<List<RegistrationRequestModel>> getPending() async {
    final response = await _dio.get('/api/registration/pending');
    final List data = response.data['data'] as List;
    return data
        .map(
          (e) => RegistrationRequestModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> approve(String id) async {
    await _dio.post('/api/registration/$id/approve');
  }

  Future<void> reject(String id, String reason) async {
    await _dio.post('/api/registration/$id/reject', data: {'reason': reason});
  }
}
