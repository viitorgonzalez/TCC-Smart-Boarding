import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smartboarding_app/core/constants/api_constants.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';

class NotificationService {
  final Dio _dio = DioClient.instance;

  /// Pega o token FCM do dispositivo e registra no backend.
  /// Chamado automaticamente após login. Falha silenciosamente para não
  /// bloquear o fluxo do usuário se o Firebase não estiver configurado.
  Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _dio.post(
        ApiConstants.devicesToken,
        data: {'token': token},
      );
    } catch (_) {
      // Intencional: push não é crítico para o funcionamento do app.
    }
  }

  /// Envia uma notificação broadcast para todos os dispositivos registrados.
  /// Exclusivo para administradores.
  Future<void> broadcast(String title, String body) async {
    try {
      await _dio.post(
        ApiConstants.notificationsBroadcast,
        data: {'title': title, 'body': body},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Sem permissão para enviar notificações.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tempo de conexão esgotado. Verifique a rede.');
      }
      throw Exception('Erro ao enviar notificação.');
    }
  }
}
