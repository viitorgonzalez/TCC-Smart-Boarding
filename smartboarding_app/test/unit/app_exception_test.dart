import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/errors/app_exception.dart';

DioException _dio({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  dynamic body,
}) {
  final req = RequestOptions(path: '/api/lists');
  return DioException(
    requestOptions: req,
    type: type,
    response: status == null && body == null
        ? null
        : Response(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  group('mensagem vinda da API', () {
    // A API manda o motivo real no corpo. Preferir a mensagem genérica do status
    // esconderia justamente a informação útil.
    test('usa "error" do corpo quando existe', () {
      final e = _dio(
        status: 409,
        body: {'code': 'LIST_CLOSED', 'error': 'A lista já foi fechada.'},
      );
      expect(AppException.fromError(e), 'A lista já foi fechada.');
    });

    test('usa "message" quando é esse o campo', () {
      final e = _dio(status: 400, body: {'message': 'Código expirado.'});
      expect(AppException.fromError(e), 'Código expirado.');
    });

    test('corpo sem mensagem cai no texto do status', () {
      final e = _dio(status: 404, body: {'code': 'NOT_FOUND'});
      expect(AppException.fromError(e), 'Recurso não encontrado.');
    });

    test('mensagem vazia não é usada', () {
      final e = _dio(status: 401, body: {'error': ''});
      expect(
        AppException.fromError(e),
        'Sessão expirada. Faça login novamente.',
      );
    });
  });

  group('por status HTTP', () {
    test('cada status tem texto próprio', () {
      expect(
        AppException.fromError(_dio(status: 400)),
        'Dados inválidos na requisição.',
      );
      expect(
        AppException.fromError(_dio(status: 401)),
        contains('Sessão expirada'),
      );
      expect(AppException.fromError(_dio(status: 403)), contains('permissão'));
      expect(
        AppException.fromError(_dio(status: 404)),
        'Recurso não encontrado.',
      );
      expect(AppException.fromError(_dio(status: 409)), contains('Conflito'));
      expect(AppException.fromError(_dio(status: 422)), 'Dados inválidos.');
      expect(
        AppException.fromError(_dio(status: 500)),
        'Erro no servidor. Tente novamente.',
      );
      expect(
        AppException.fromError(_dio(status: 503)),
        'Erro no servidor. Tente novamente.',
      );
    });

    test('status fora da lista aparece no texto', () {
      expect(AppException.fromError(_dio(status: 418)), 'Erro 418.');
    });

    test('sem status vira "desconhecido"', () {
      expect(
        AppException.fromError(_dio(status: null, body: {})),
        'Erro desconhecido.',
      );
    });
  });

  group('falha de rede', () {
    test('timeout de conexão e erro de conexão falam de rede', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          AppException.fromError(_dio(type: t)),
          'Sem conexão com o servidor. Verifique sua rede.',
        );
      }
    });

    test('receiveTimeout fala de demora, não de rede caída', () {
      expect(
        AppException.fromError(_dio(type: DioExceptionType.receiveTimeout)),
        'O servidor demorou a responder. Tente novamente.',
      );
    });

    test('cancelamento cai no genérico de conexão', () {
      expect(
        AppException.fromError(_dio(type: DioExceptionType.cancel)),
        'Erro de conexão. Tente novamente.',
      );
    });
  });

  test('AppException devolve a própria mensagem', () {
    expect(
      AppException.fromError(const AppException('Senha muito curta')),
      'Senha muito curta',
    );
    expect(const AppException('x').toString(), 'x');
  });

  // Erro que não é nem AppException nem DioException não pode vazar stack trace
  // pro usuário.
  test('erro qualquer vira mensagem genérica', () {
    expect(
      AppException.fromError(StateError('bug interno')),
      'Erro inesperado. Tente novamente.',
    );
    expect(
      AppException.fromError('string solta'),
      'Erro inesperado. Tente novamente.',
    );
  });
}
