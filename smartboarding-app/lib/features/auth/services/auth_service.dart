import 'package:dio/dio.dart';
import 'package:smartboarding_app/core/constants/api_constants.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';
import 'package:smartboarding_app/features/auth/models/auth_token.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  Future<AuthToken> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthToken.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('E-mail ou senha incorretos.');
      }
      throw Exception('Erro ao conectar com o servidor. Tente novamente.');
    }
  }
}
