import 'package:flutter/material.dart';
import '../../features/auth/models/auth_token.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/google_auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _storage = StorageService();
  final _googleAuth = GoogleAuthService();

  AuthStatus _status = AuthStatus.unknown;
  AuthToken? _token;

  AuthStatus get status => _status;
  AuthToken? get token => _token;
  bool get isAdmin => _token?.role == 'ADMIN';
  bool get isStudent => _token?.role == 'STUDENT';

  /// Chamado no boot do app para restaurar sessão salva.
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
    // TODO(firebase): registrar device token FCM aqui após ativar o push.
    // Ver docs/firebase-setup.md, passo 7 (NotificationService().registerToken).
    notifyListeners();
  }

  /// Cadastro proprio: a API ja devolve a sessao, entao o aluno entra direto.
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

  /// Entra com Google: o plugin devolve o ID token, o backend devolve a sessão.
  /// Retorna false quando o usuário desiste da escolha de conta -- desistir não
  /// é falha, e tratar como erro encheria a tela de vermelho à toa.
  Future<bool> signInWithGoogle() async {
    final idToken = await _googleAuth.signIn();
    if (idToken == null) return false;
    _token = await _authService.signInWithGoogle(idToken);
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    // TODO(firebase): remover device token FCM aqui após ativar o push.
    // Ver docs/firebase-setup.md, passo 8 (NotificationService().removeToken).
    // Sai do Google junto: sem isso o proximo login reentraria sozinho na
    // conta anterior, sem perguntar.
    await _googleAuth.signOut();
    await _authService.logout();
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
