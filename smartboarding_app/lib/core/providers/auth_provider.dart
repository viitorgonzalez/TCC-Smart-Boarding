import 'package:flutter/material.dart';
import '../../features/auth/models/auth_token.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/google_auth_service.dart';
import '../navigation/app_navigator.dart';
import '../services/dio_client.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _storage = StorageService();
  final _googleAuth = GoogleAuthService();

  AuthStatus _status = AuthStatus.unknown;
  AuthToken? _token;

  bool _encerrando = false;

  AuthProvider() {
    DioClient.onUnauthorized = _sessaoExpirou;
  }

  AuthStatus get status => _status;
  AuthToken? get token => _token;
  bool get isAdmin => _token?.role == 'ADMIN';
  bool get isStudent => _token?.role == 'STUDENT';

  Future<void> init() async {
    final storedToken = await _storage.getToken();
    if (storedToken != null) {
      _token = AuthToken(
        token: storedToken,
        fullName: await _storage.getFullName() ?? '',
        role: await _storage.getRole() ?? '',
        email: await _storage.getEmail() ?? '',
      );
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _token = await _authService.login(email, password);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _token = await _authService.signup(
      fullName: fullName,
      email: email,
      password: password,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    final idToken = await _googleAuth.signIn();
    if (idToken == null) return false;
    _token = await _authService.signInWithGoogle(idToken);
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _googleAuth.signOut();
    await _authService.logout();
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _sessaoExpirou() async {
    if (_encerrando || _status != AuthStatus.authenticated) return;
    _encerrando = true;
    try {
      await logout();
    } finally {
      _encerrando = false;
    }
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
  }
}
