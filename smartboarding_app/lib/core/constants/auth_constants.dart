/// Client ID **Web** do Google — não o do Android. É ele que vai no `aud` do ID
/// token, e o backend compara com o mesmo valor; trocar pelo do Android faz o
/// login falhar sempre, com erro que não aponta a causa.
///
/// Vem por `--dart-define` porque muda entre o projeto de dev e o de produção.
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Vazio = build sem Google configurado; a tela esconde o botão.
bool get googleSignInEnabled => googleWebClientId.isNotEmpty;
