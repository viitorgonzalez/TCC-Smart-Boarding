import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/auth_constants.dart';

class GoogleAuthService {
  final GoogleSignIn _google;
  bool _iniciado = false;

  GoogleAuthService([GoogleSignIn? google])
    : _google = google ?? GoogleSignIn.instance;

  Future<void> _garantirInicializado() async {
    if (_iniciado) return;
    if (!googleSignInEnabled) {
      throw StateError(
        'Login com Google não configurado nesta build '
        '(--dart-define=GOOGLE_WEB_CLIENT_ID).',
      );
    }
    await _google.initialize(serverClientId: googleWebClientId);
    _iniciado = true;
  }

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

  Future<void> signOut() async {
    if (!googleSignInEnabled) return;
    await _garantirInicializado();
    await _google.signOut();
  }
}
