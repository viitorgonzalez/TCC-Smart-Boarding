import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;

  static String fromError(Object e) {
    if (e is AppException) return e.message;
    if (e is DioException) return _fromDio(e);
    return 'Erro inesperado. Tente novamente.';
  }

  static String _fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        'Sem conexão com o servidor. Verifique sua rede.',
      DioExceptionType.receiveTimeout =>
        'O servidor demorou a responder. Tente novamente.',
      DioExceptionType.badResponse => _fromStatus(
        e.response?.statusCode,
        entrando: _ehPortaDeEntrada(e),
      ),
      _ => 'Erro de conexão. Tente novamente.',
    };
  }

  static bool _ehPortaDeEntrada(DioException e) =>
      e.requestOptions.path.contains('/auth/');

  static String _fromStatus(int? code, {bool entrando = false}) =>
      switch (code) {
        400 => 'Dados inválidos na requisição.',
        401 when entrando => 'E-mail ou senha incorretos.',
        401 => 'Sessão expirada. Faça login novamente.',
        403 => 'Você não tem permissão para esta ação.',
        404 => 'Recurso não encontrado.',
        409 => 'Conflito: já existe um registro com esses dados.',
        422 => 'Dados inválidos.',
        500 || 502 || 503 => 'Erro no servidor. Tente novamente.',
        _ => 'Erro ${code ?? "desconhecido"}.',
      };
}
