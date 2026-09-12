import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/auth_constants.dart';

/// Login com Google. Devolve o ID token que a nossa API valida — o app nunca
/// decide sozinho quem entrou: quem confirma a identidade é o backend, contra
/// o próprio Google.
class GoogleAuthService {
  final GoogleSignIn _google;
  bool _iniciado = false;

  GoogleAuthService([GoogleSignIn? google])
    : _google = google ?? GoogleSignIn.instance;

  /// O serverClientId é o que faz o Google emitir um token destinado à NOSSA
  /// API. Sem ele o token sai endereçado ao app e o backend recusa no `aud`.
  Future<void> _garantirInicializado() async {
    if (_iniciado) return;
    // Falha antes de abrir a tela de contas: deixar passar faria o usuario
    // escolher a conta pra so entao tomar 401.
    if (!googleSignInEnabled) {
      throw StateError(
        'Login com Google não configurado nesta build '
        '(--dart-define=GOOGLE_WEB_CLIENT_ID).',
      );
    }
    await _google.initialize(serverClientId: googleWebClientId);
    _iniciado = true;
  }

  /// Devolve o ID token, ou null se o usuário desistiu.
  ///
  /// Desistir não é erro: cancelar a escolha de conta é uma ação legítima, e
  /// tratar como falha encheria a tela de mensagem vermelha à toa.
  Future<String?> signIn() async {
    await _garantirInicializado();
    try {
      final conta = await _google.authenticate();
      return conta.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Sair do Google junto do logout do app: sem isto, o próximo login
  /// reentraria sozinho na conta anterior sem perguntar.
  Future<void> signOut() async {
    // Inicializa antes: depois de reabrir o app a sessao vem do storage e o
    // signIn() nunca rodou neste processo, entao sair era no-op -- e o proximo
    // "Entrar com Google" reentrava sozinho na conta anterior, sem perguntar.
    if (!googleSignInEnabled) return;
    await _garantirInicializado();
    await _google.signOut();
  }
}
