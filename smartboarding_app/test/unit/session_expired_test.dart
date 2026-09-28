import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/core/services/dio_client.dart';

import '../support/fake_http.dart';

/// O 401 tratado só como texto deixava o usuário preso: a mensagem mandava
/// entrar de novo, mas a sessão morta continuava valendo e toda ação falhava.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AuthProvider> sessaoAberta(FakeHttpAdapter http) async {
    final auth = AuthProvider();
    await auth.init();
    expect(
      auth.status,
      AuthStatus.authenticated,
      reason: 'o teste precisa começar de uma sessão viva',
    );
    return auth;
  }

  test('401 numa rota autenticada derruba a sessão', () async {
    final http = await installFakeHttp(token: 'token-vencido');
    final auth = await sessaoAberta(http);

    http.on('GET', '/me', status: 401);
    await expectLater(
      DioClient.instance.get<void>('/me'),
      throwsA(isA<DioException>()),
    );

    // O encerramento sai do interceptor sem ser esperado -- na prática custa
    // um frame, mas o teste precisa deixar a fila girar.
    await pumpEventQueue();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.token, isNull);
  });

  test('401 no login não mexe na sessão de quem já está dentro', () async {
    final http = await installFakeHttp(token: 'token-bom');
    final auth = await sessaoAberta(http);

    // Senha errada responde 401 igual a token vencido. Tratar os dois do mesmo
    // jeito faria um erro de digitação derrubar quem estava logado.
    http.on('POST', '/auth/login', status: 401);
    await expectLater(
      DioClient.instance.post<void>('/auth/login'),
      throwsA(isA<DioException>()),
    );

    await pumpEventQueue();

    expect(auth.status, AuthStatus.authenticated);
  });

  test('403 não derruba a sessão: é permissão, não sessão vencida', () async {
    final http = await installFakeHttp(token: 'token-bom');
    final auth = await sessaoAberta(http);

    http.on('POST', '/routes/abc/invite-codes', status: 403);
    await expectLater(
      DioClient.instance.post<void>('/routes/abc/invite-codes'),
      throwsA(isA<DioException>()),
    );
    await pumpEventQueue();

    expect(auth.status, AuthStatus.authenticated);
  });
}
