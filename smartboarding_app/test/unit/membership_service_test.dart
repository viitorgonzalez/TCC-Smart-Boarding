import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/auth/services/auth_service.dart';
import 'package:smartboarding_app/core/services/storage_service.dart';
import 'package:smartboarding_app/features/membership/services/membership_service.dart';
import 'package:smartboarding_app/features/trip/services/trip_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;

  setUp(() async {
    http = await installFakeHttp();
  });

  group('MembershipService', () {
    test('lista vazia nao quebra o parsing', () async {
      http.on('GET', '/api/me/routes', body: {'data': []});

      expect(await MembershipService().myRoutes(), isEmpty);
    });

    test('entrar manda so o codigo e devolve a rota', () async {
      http.on(
        'POST',
        '/api/me/routes',
        body: {
          'data': {
            'id': 'r1',
            'name': 'Rota Universitária',
            'isActive': true,
            'createdAt': '2026-09-01T10:00:00',
          },
        },
      );

      final rota = await MembershipService().joinWithCode('RU7K2M');

      expect(rota.name, 'Rota Universitária');
      expect(http.requests.single.data, {'code': 'RU7K2M'});
    });

    // O id do usuario sai do token no backend: mandar userId daqui abriria
    // caminho pra operar em nome de outro.
    test('sair usa DELETE na rota e nao manda userId', () async {
      http.on(
        'DELETE',
        '/api/me/routes/r1',
        body: {
          'data': {'success': true},
        },
      );

      await MembershipService().leave('r1');

      expect(http.requests.single.method, 'DELETE');
      expect(http.requests.single.path, '/api/me/routes/r1');
      expect(http.requests.single.data, isNull);
    });
  });

  group('AuthService.signup', () {
    test('guarda a sessao devolvida pelo cadastro', () async {
      http.on(
        'POST',
        '/api/auth/signup',
        body: {
          'data': {
            'token': 'jwt-novo',
            'fullName': 'Joao Teste',
            'role': 'STUDENT',
          },
        },
      );

      final token = await AuthService().signup(
        fullName: 'Joao Teste',
        email: 'joao@edu.unifor.br',
        password: 'sb@2026',
      );

      expect(token.role, 'STUDENT');
      // Sem persistir aqui, o aluno cairia logado mas perderia a sessao ao
      // fechar o app -- e o cadastro nao pode ser refeito.
      expect(await StorageService().getToken(), 'jwt-novo');
    });

    // Campo opcional vazio viraria string vazia no banco em vez de null.
    test('campos opcionais vazios nao sao enviados', () async {
      http.on(
        'POST',
        '/api/auth/signup',
        body: {
          'data': {'token': 'jwt', 'fullName': 'Joao', 'role': 'STUDENT'},
        },
      );

      await AuthService().signup(
        fullName: 'Joao',
        email: 'joao@edu.unifor.br',
        password: 'sb@2026',
        course: '',
        phone: '',
      );

      final data = http.requests.single.data as Map;
      expect(data.containsKey('course'), isFalse);
      expect(data.containsKey('phone'), isFalse);
      expect(data.containsKey('institutionId'), isFalse);
    });

    test('o papel nunca viaja no corpo do cadastro', () async {
      http.on(
        'POST',
        '/api/auth/signup',
        body: {
          'data': {'token': 'jwt', 'fullName': 'Joao', 'role': 'STUDENT'},
        },
      );

      await AuthService().signup(
        fullName: 'Joao',
        email: 'joao@edu.unifor.br',
        password: 'sb@2026',
      );

      expect((http.requests.single.data as Map).containsKey('role'), isFalse);
    });
  });

  group('TripService', () {
    Map<String, dynamic> status() => {
      'data': {
        'listId': 'l1',
        'routeName': 'Rota Universitária',
        'startedAt': null,
        'finishedAt': null,
        'stops': [],
      },
    };

    test(
      'status, start, checkpoint e finish batem nos endpoints certos',
      () async {
        http.always(body: status());
        final s = TripService();

        await s.status('l1');
        expect(http.requests.last.path, '/api/trip/l1');

        await s.start('l1');
        expect(http.requests.last.path, '/api/trip/l1/start');

        await s.checkpoint('l1', 'p1');
        expect(http.requests.last.path, '/api/trip/l1/checkpoint/p1');

        await s.finish('l1');
        expect(http.requests.last.path, '/api/trip/l1/finish');
      },
    );
  });
}
