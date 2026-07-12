import '../../../core/services/dio_client.dart';

class NotificationService {
  final _dio = DioClient.instance;

  Future<void> broadcast(String title, String body) async {
    await _dio.post('/api/notifications/broadcast', data: {
      'title': title,
      'body': body,
    });
  }

  /// Registra o token FCM do dispositivo no backend.
  Future<void> registerToken(String token, String platform) async {
    await _dio.post('/api/devices/token', data: {
      'token': token,
      'platform': platform,
    });
  }

  /// Remove o token FCM ao fazer logout.
  Future<void> removeToken() async {
    await _dio.delete('/api/devices/token');
  }
}
