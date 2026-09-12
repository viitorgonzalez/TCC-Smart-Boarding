import '../../../core/services/dio_client.dart';
import '../models/student_profile_model.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = DioClient.instance;

  /// [routeId] nulo traz o sistema inteiro; o app usa o filtro por rota porque
  /// a base cresce sem teto e o admin trabalha por rota.
  Future<List<UserModel>> getUsers({String? routeId}) async {
    final response = await _dio.get(
      '/api/users',
      queryParameters: {'routeId': ?routeId},
    );
    final List data = response.data['data'] as List;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentProfile> getProfile(String userId) async {
    final response = await _dio.get('/api/users/$userId/profile');
    return StudentProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<StudentProfile> setActive(String userId, bool active) async {
    final response = await _dio.patch(
      '/api/users/$userId/status',
      data: {'active': active},
    );
    return StudentProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Concede ou retira acesso administrativo. Não cria conta — a conta já é da
  /// pessoa.
  Future<StudentProfile> setRole(String userId, String role) async {
    final response = await _dio.patch(
      '/api/users/$userId/role',
      data: {'role': role},
    );
    return StudentProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
