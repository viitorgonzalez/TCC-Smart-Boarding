import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/errors/app_exception.dart';
import 'package:smartboarding_app/features/auth/services/auth_service.dart';
import 'package:smartboarding_app/core/services/storage_service.dart';
import 'package:smartboarding_app/features/users/services/user_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;

  setUp(() async {
    http = await installFakeHttp();
  });

  group('AuthService.login', () {
    test('guarda o token e devolve nome e papel', () async {
      http.on(
        'POST',
        '/api/auth/login',
        body: {
          'data': {
            'token': 'jwt-abc',
            'fullName': 'Fernanda Lima',
            'role': 'STUDENT',
          },
        },
      );

      final token = await AuthService().login(
        'fernanda@edu.unifor.br',
        'sb@2026',
      );

      expect(token.token, 'jwt-abc');
      expect(token.fullName, 'Fernanda Lima');
      expect(token.role, 'STUDENT');
      // Sessão persistida: sem isso o app pediria login a cada abertura.
      expect(await StorageService().getToken(), 'jwt-abc');
      expect(await StorageService().getEmail(), 'fernanda@edu.unifor.br');
    });

    // O interceptor converte DioException em AppException com texto legível —
    // é o que a tela mostra.
    test('credencial inválida vira mensagem amigável', () async {
      http.on(
        'POST',
        '/api/auth/login',
        status: 401,
        body: {'code': 'UNAUTHORIZED', 'error': 'Credenciais inválidas'},
      );

      await expectLater(
        AuthService().login('fernanda@edu.unifor.br', 'errada'),
        throwsA(
          isA<DioException>().having(
            (e) => AppException.fromError(e),
            'mensagem',
            'Credenciais inválidas',
          ),
        ),
      );
      expect(await StorageService().getToken(), isNull);
    });
  });

  /// RN22: o app não pode diferenciar conta existente de inexistente.
  test(
    'forgotPassword não devolve nada que revele a existência da conta',
    () async {
      http.on(
        'POST',
        '/api/auth/forgot-password',
        body: {
          'data': {'success': true},
        },
      );

      await AuthService().forgotPassword('ninguem@edu.unifor.br');

      expect(http.requests.single.data, {'email': 'ninguem@edu.unifor.br'});
    },
  );

  test('resetPassword manda e-mail, código e senha nova', () async {
    http.on(
      'POST',
      '/api/auth/reset-password',
      body: {
        'data': {'success': true},
      },
    );

    await AuthService().resetPassword(
      email: 'fernanda@edu.unifor.br',
      code: '123456',
      newPassword: 'novaSenha1',
    );

    expect(http.requests.single.data, {
      'email': 'fernanda@edu.unifor.br',
      'code': '123456',
      'newPassword': 'novaSenha1',
    });
  });

  test('logout limpa a sessão inteira', () async {
    http = await installFakeHttp(token: 'jwt-antigo');

    await AuthService().logout();

    expect(await StorageService().getToken(), isNull);
    expect(await StorageService().getRole(), isNull);
  });

  group('UserService', () {
    test('sem routeId não manda o parâmetro', () async {
      http.on('GET', '/api/users', body: {'data': []});

      await UserService().getUsers();

      expect(
        http.requests.single.queryParameters.containsKey('routeId'),
        isFalse,
      );
    });

    test('com routeId filtra pela rota', () async {
      http.on('GET', '/api/users', body: {'data': []});

      await UserService().getUsers(routeId: 'rota-1');

      expect(http.requests.single.queryParameters['routeId'], 'rota-1');
    });

    test('lista vazia não quebra o parsing', () async {
      http.on('GET', '/api/users', body: {'data': []});

      expect(await UserService().getUsers(), isEmpty);
    });

    test('getProfile parseia o perfil breve', () async {
      http.always(
        body: {
          'data': {
            'id': 'aluno-1',
            'fullName': 'Fernanda Lima',
            'isActive': true,
            'recentAttendance': ['2026-09-09'],
            'statusHistory': [],
          },
        },
      );

      final p = await UserService().getProfile('aluno-1');

      expect(p.fullName, 'Fernanda Lima');
      expect(p.recentAttendance, hasLength(1));
    });

    test(
      'setActive manda o novo estado e devolve o perfil atualizado',
      () async {
        http.always(
          body: {
            'data': {
              'id': 'aluno-1',
              'fullName': 'Fernanda Lima',
              'isActive': false,
            },
          },
        );

        final p = await UserService().setActive('aluno-1', false);

        expect(p.isActive, isFalse);
        expect(http.requests.single.data, {'active': false});
        expect(http.requests.single.method, 'PATCH');
      },
    );

    test('register manda os quatro campos', () async {
      http.on('POST', '/api/auth/register', body: {'data': {}});

      await UserService().register(
        fullName: 'Novo Admin',
        email: 'novo@admin.com',
        password: 'senha123',
        role: 'ADMIN',
      );

      expect(http.requests.single.data, {
        'fullName': 'Novo Admin',
        'email': 'novo@admin.com',
        'password': 'senha123',
        'role': 'ADMIN',
      });
    });
  });

  /// O JWT guardado tem que viajar em toda requisição — sem isso o app logado
  /// tomaria 401 em tudo.
  test('token salvo vai no header Authorization', () async {
    http = await installFakeHttp(token: 'jwt-abc');
    http.on('GET', '/api/users', body: {'data': []});

    await UserService().getUsers();

    expect(http.requests.single.headers['Authorization'], 'Bearer jwt-abc');
  });

  test('sem token salvo não manda header de autorização', () async {
    http.on('GET', '/api/users', body: {'data': []});

    await UserService().getUsers();

    expect(http.requests.single.headers.containsKey('Authorization'), isFalse);
  });
}
