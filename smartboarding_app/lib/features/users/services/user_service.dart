import '../../../core/services/dio_client.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = DioClient.instance;

  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get('/api/users');
    final List data = response.data['data'] as List;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cria um usuário (ADMIN-only). Backend: POST /api/auth/register.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    await _dio.post('/api/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
    });
  }
}
