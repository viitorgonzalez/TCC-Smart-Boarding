import 'package:flutter/foundation.dart';

class ApiConstants {
  /// URL base da API. Varia por plataforma para funcionar em emuladores,
  /// simuladores e web sem alterar o código manualmente.
  ///
  /// - Android emulator  → 10.0.2.2 (loopback do host via QEMU)
  /// - iOS Simulator / web → localhost
  ///
  /// Em produção, substitua pelo domínio real do servidor.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String users = '/api/users';
  static const String routes = '/api/routes';
  static const String listsToday = '/api/lists/today';
  static const String lists = '/api/lists';
  static const String reports = '/api/reports';
  static const String notificationsBroadcast = '/api/notifications/broadcast';
  static const String devicesToken = '/api/devices/token';
}
