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

  /// Trava de reentrância: uma tela que dispara várias requisições toma
  /// vários 401 de uma vez, e sem isso cada um encerraria a sessão de novo.
  bool _encerrando = false;

  AuthProvider() {
    DioClient.onUnauthorized = _sessaoExpirou;
  }

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

  /// O servidor recusou o token: a sessão acabou (expirou, conta desativada ou
  /// removida). Só avisar não basta — sem derrubar a sessão o usuário fica
  /// numa tela onde toda ação falha, lendo "faça login novamente" sem ter como.
  Future<void> _sessaoExpirou() async {
    if (_encerrando || _status != AuthStatus.authenticated) return;
    _encerrando = true;
    try {
      await logout();
    } finally {
      _encerrando = false;
    }
    // O AuthGate já troca pro login sozinho, mas ele é a tela de baixo: sem
    // desempilhar, o que estava aberto por cima continua na frente.
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
  }
}
