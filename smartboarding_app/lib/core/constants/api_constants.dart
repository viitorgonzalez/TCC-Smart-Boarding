class ApiConstants {
  /// Base URL da API, configurável no build/run sem recompilar código:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
  ///
  /// Padrão: emulador Android (10.0.2.2 mapeia para o localhost da máquina).
  /// Para dispositivo físico (ex: iPhone no cabo), passe o IP da sua máquina
  /// na rede local via --dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
