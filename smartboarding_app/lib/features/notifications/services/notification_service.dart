import '../../../core/services/dio_client.dart';
import '../models/notification_model.dart';
import '../models/scheduled_notification_model.dart';

class NotificationService {
  final _dio = DioClient.instance;

  /// [durationHours] nulo é aviso sem prazo.
  Future<void> broadcast(
    String title,
    String body, {
    required String routeId,
    int? durationHours,
  }) async {
    await _dio.post(
      '/api/notifications/broadcast',
      data: {
        'title': title,
        'body': body,
        'routeId': routeId,
        'durationHours': ?durationHours,
      },
    );
  }

  /// Avisos visíveis pra quem está logado (aluno: gerais + da rota dele).
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get('/api/notifications');
    final List data = response.data['data'] as List;
    return data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerToken(String token, String platform) async {
    await _dio.post(
      '/api/devices/token',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> removeToken() async {
    await _dio.delete('/api/devices/token');
  }

  /// Em lote: apagar um a um seria N requisições e N recargas de tela.
  Future<void> deleteNotifications(List<String> ids) async {
    await _dio.delete('/api/notifications', data: ids);
  }

  Future<List<ScheduledNotificationModel>> getScheduled(String routeId) async {
    final response = await _dio.get(
      '/api/notifications/scheduled',
      queryParameters: {'routeId': routeId},
    );
    final List data = response.data['data'] as List;
    return data
        .map(
          (e) => ScheduledNotificationModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> createScheduled({
    required String routeId,
    required String title,
    required String body,
    required String frequency,
    required String sendAt,
    int? dayOfWeek,
    int? durationHours,
  }) async {
    await _dio.post(
      '/api/notifications/scheduled',
      data: {
        'routeId': routeId,
        'title': title,
        'body': body,
        'frequency': frequency,
        'sendAt': sendAt,
        'dayOfWeek': ?dayOfWeek,
        'durationHours': ?durationHours,
      },
    );
  }

  Future<void> toggleScheduled(String id, bool active) async {
    await _dio.patch(
      '/api/notifications/scheduled/$id',
      data: {'active': active},
    );
  }

  Future<void> deleteScheduled(String id) async {
    await _dio.delete('/api/notifications/scheduled/$id');
  }
}
