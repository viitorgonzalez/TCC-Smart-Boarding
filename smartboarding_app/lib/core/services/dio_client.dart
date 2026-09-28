import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import 'storage_service.dart';

class DioClient {
  static Dio? _instance;
  static final _storage = StorageService();

  /// Chamado quando o servidor recusa o token da sessão. Quem liga é o
  /// [AuthProvider], que derruba a sessão e devolve o usuário ao login.
  ///
  /// É um gancho, e não uma chamada direta ao provider, porque o cliente HTTP
  /// é estático e não enxerga a árvore de widgets.
  static void Function()? onUnauthorized;

  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      _ErrorInterceptor(),
      // Descomente para debug:
      // LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}

// ─── Injeta JWT em todas as requisições ──────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─── Converte DioException em AppException com mensagem amigável ─────────────

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_ehPortaDeEntrada(err)) {
      DioClient.onUnauthorized?.call();
    }

    final message = AppException.fromError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppException(message),
        message: message,
      ),
    );
  }

  /// 401 em `/auth/*` é credencial errada de quem está tentando entrar, não
  /// sessão vencida — derrubar a sessão ali faria um erro de digitação na
  /// senha desempilhar as telas de quem nem estava logado.
  bool _ehPortaDeEntrada(DioException err) =>
      err.requestOptions.path.contains('/auth/');
}
