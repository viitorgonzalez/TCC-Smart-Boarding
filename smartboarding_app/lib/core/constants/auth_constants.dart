/// Client ID **Web** do Google. É ele que o app informa como serverClientId pra
/// receber um ID token destinado à nossa API — o backend compara este mesmo
/// valor no campo "aud" do token.
///
/// Usar o client ID do Android aqui faria o "aud" não bater e o login falhar
/// sempre, com uma mensagem que não aponta a causa.
///
/// Vem por `--dart-define` e não fixo no código: o valor muda entre o projeto
/// do Google de dev e o de produção, e valor que varia por ambiente não mora no
/// repositório. Não é segredo (vai embutido no APK de qualquer forma; o que
/// protege a conta é o par pacote + SHA-1 registrado no Google Cloud), mas
/// scanner de segredo o sinaliza e a regra do repo vale igual.
///
/// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=SEU_ID.apps.googleusercontent.com`
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Vazio significa "esta build não tem login com Google configurado". A tela
/// esconde o botão em vez de oferecer um caminho que morre no meio.
bool get googleSignInEnabled => googleWebClientId.isNotEmpty;
