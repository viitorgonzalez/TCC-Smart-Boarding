const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

bool get googleSignInEnabled => googleWebClientId.isNotEmpty;
