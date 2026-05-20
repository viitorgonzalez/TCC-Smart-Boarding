import 'package:flutter/foundation.dart';
import 'package:smartboarding_app/core/services/storage_service.dart';
import 'package:smartboarding_app/features/auth/models/auth_token.dart';
import 'package:smartboarding_app/features/auth/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  AuthToken? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthToken? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> restoreSession() async {
    final saved = await _storage.getAuthToken();
    if (saved != null) {
      _currentUser = saved;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final auth = await _authService.login(email, password);
      await _storage.saveAuthToken(auth);
      _currentUser = auth;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clearAuthToken();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
