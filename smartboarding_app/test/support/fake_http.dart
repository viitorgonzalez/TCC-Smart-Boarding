import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';
import 'package:smartboarding_app/core/services/storage_service.dart';

/// Substitui só o transporte HTTP do Dio real. Interceptor de JWT e de erro
/// continuam rodando, então o teste exercita o caminho de verdade -- inclusive a
/// conversão de DioException em AppException.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, ({int status, Object? body})> _routes = {};
  ({int status, Object? body})? _fallback;

  void on(String method, String path, {int status = 200, Object? body}) {
    _routes['${method.toUpperCase()} $path'] = (status: status, body: body);
  }

  void always({int status = 200, Object? body}) {
    _fallback = (status: status, body: body);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method.toUpperCase()} ${options.path}';
    final match = _routes[key] ?? _fallback;
    if (match == null) {
      throw StateError('Nenhuma resposta configurada para $key');
    }
    return ResponseBody.fromString(
      jsonEncode(match.body ?? {}),
      match.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Instala o adaptador falso no Dio compartilhado e zera o storage.
///
/// O clearAuth explicito e necessario: o StorageService cacheia a instancia de
/// SharedPreferences num estatico (de proposito -- o interceptor le o token a
/// cada requisicao), e esse cache sobrevive ao setMockInitialValues. Sem limpar
/// pela instancia, a sessao de um teste vaza pro proximo.
Future<FakeHttpAdapter> installFakeHttp({String? token}) async {
  SharedPreferences.setMockInitialValues({});
  await StorageService().clearAuth();
  if (token != null) {
    await StorageService().saveAuth(
      token: token,
      fullName: 'Fernanda Lima',
      role: 'STUDENT',
      email: 'fernanda@edu.unifor.br',
    );
  }
  final adapter = FakeHttpAdapter();
  DioClient.instance.httpClientAdapter = adapter;
  return adapter;
}
