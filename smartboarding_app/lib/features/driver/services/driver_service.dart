import '../../../core/services/dio_client.dart';

class DriverService {
  final _dio = DioClient.instance;

  /// Envia a notificação de saída para os inscritos ativos da lista.
  /// Backend: POST /api/lists/{id}/notifications/departure (Gap 2 — DRIVER/ADMIN).
  /// Retorna quantos alunos foram notificados.
  Future<int> sendDeparture(String listId, {String? title, String? body}) async {
    final response = await _dio.post(
      '/api/lists/$listId/notifications/departure',
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    return response.data['data']['notified'] as int;
  }
}
