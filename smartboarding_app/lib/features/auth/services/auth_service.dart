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

  /// Troca o ID token do Google pela sessão da nossa API.
  ///
  /// Quem valida o token é o backend, contra o próprio Google — o app só
  /// transporta. Confiar no app pra dizer quem entrou deixaria qualquer um
  /// forjar uma sessão.
  Future<AuthToken> signInWithGoogle(String idToken) async {
    final response = await _dio.post(
      '/api/auth/google',
      data: {'idToken': idToken},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final token = AuthToken.fromLogin(data);
    await _storage.saveAuth(
      token: token.token,
      fullName: token.fullName,
      role: token.role,
      email: token.email,
    );
    return token;
  }

  /// Define a senha local de quem entrou pelo Google.
  Future<void> setLocalPassword(String password) async {
    await _dio.post('/api/me/password', data: {'password': password});
  }

  /// Cadastro próprio. A API já devolve a sessão pronta, então o aluno cai
  /// logado — não faz sentido pedir de novo o que ele acabou de digitar.
  ///
  /// A conta nasce SEM rota: ele chega na home no estado "sem rota" e entra
  /// numa usando o código do admin.
  Future<AuthToken> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/signup',
      data: {'fullName': fullName, 'email': email, 'password': password},
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

  /// Responde igual havendo conta ou não — a tela nunca deve afirmar que o
  /// e-mail existe (RN22).
  Future<void> forgotPassword(String email) async {
    await _dio.post('/api/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  Future<void> logout() async {
    await _storage.clearAuth();
  }
}
