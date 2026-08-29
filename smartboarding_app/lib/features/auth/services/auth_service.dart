import '../../../core/services/dio_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_token.dart';

class AuthService {
  final _dio = DioClient.instance;
  final _storage = StorageService();

  Future<AuthToken> login(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final token = AuthToken.fromLogin(data, email);
    await _storage.saveAuth(
      token: token.token,
      fullName: token.fullName,
      role: token.role,
      email: token.email,
    );
    return token;
  }

  Future<void> logout() async {
    await _storage.clearAuth();
  }
}
