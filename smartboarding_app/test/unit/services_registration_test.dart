import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/registration/services/institution_service.dart';
import 'package:smartboarding_app/features/registration/services/registration_service.dart';
import 'package:smartboarding_app/features/trip/services/trip_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;

  setUp(() async {
    http = await installFakeHttp();
  });

  group('RegistrationService', () {
    test('gerar convite manda só o e-mail', () async {
      http.always(
        body: {
          'data': {'success': true},
        },
      );

      await RegistrationService().generateInvite('fernanda@edu.unifor.br');

      expect(http.requests.single.path, '/api/registration/invite');
      expect(http.requests.single.data, {'email': 'fernanda@edu.unifor.br'});
    });

    test('verifyCode devolve o token do convite', () async {
      http.always(
        body: {
          'data': {'token': 'convite-x1'},
        },
      );

      final token = await RegistrationService().verifyCode(
        'fernanda@edu.unifor.br',
        '123456',
      );

      expect(token, 'convite-x1');
      expect(http.requests.single.data, {
        'email': 'fernanda@edu.unifor.br',
        'code': '123456',
      });
    });

    test('reenviar código usa o endpoint de reenvio', () async {
      http.always(
        body: {
          'data': {'success': true},
        },
      );

      await RegistrationService().resendCode('fernanda@edu.unifor.br');

      expect(http.requests.single.path, '/api/registration/resend-code');
    });

    test('getInvite lê o convite pelo token', () async {
      http.always(
        body: {
          'data': {'email': 'fernanda@edu.unifor.br', 'status': 'INVITED'},
        },
      );

      final info = await RegistrationService().getInvite('convite-x1');

      expect(info.email, 'fernanda@edu.unifor.br');
      expect(http.requests.single.path, '/api/registration/invite/convite-x1');
    });

    // Campo opcional vazio não pode virar string vazia no banco: o backend
    // guardaria "" em vez de null e a tela exibiria um campo em branco.
    test('campos opcionais vazios não são enviados', () async {
      http.always(
        body: {
          'data': {'status': 'SUBMITTED'},
        },
      );

      await RegistrationService().submit(
        token: 'convite-x1',
        fullName: 'Fernanda Lima',
        password: 'sb@2026',
        institutionId: 'inst-1',
        course: '',
        phone: '   ',
        address: null,
      );

      final data = http.requests.single.data as Map;
      expect(data.containsKey('course'), isFalse);
      expect(data.containsKey('address'), isFalse);
      expect(data['fullName'], 'Fernanda Lima');
      expect(data['institutionId'], 'inst-1');
    });

    test('campos opcionais preenchidos vão junto', () async {
      http.always(
        body: {
          'data': {'status': 'SUBMITTED'},
        },
      );

      await RegistrationService().submit(
        token: 'convite-x1',
        fullName: 'Fernanda Lima',
        password: 'sb@2026',
        institutionId: 'inst-1',
        course: 'Engenharia',
        phone: '37999990000',
        birthDate: '2004-05-10',
      );

      final data = http.requests.single.data as Map;
      expect(data['course'], 'Engenharia');
      expect(data['phone'], '37999990000');
      expect(data['birthDate'], '2004-05-10');
    });

    test('fila de pendentes vazia não quebra', () async {
      http.always(body: {'data': []});

      expect(await RegistrationService().getPending(), isEmpty);
    });

    test('aprovar e recusar batem nos endpoints certos', () async {
      http.always(
        body: {
          'data': {'success': true},
        },
      );

      await RegistrationService().approve('pedido-1');
      expect(http.requests.last.path, '/api/registration/pedido-1/approve');

      await RegistrationService().reject(
        'pedido-1',
        'Instituição não atendida',
      );
      expect(http.requests.last.path, '/api/registration/pedido-1/reject');
      expect(http.requests.last.data, {'reason': 'Instituição não atendida'});
    });
  });

  group('InstitutionService', () {
    test('lista vazia não quebra o parsing', () async {
      http.always(body: {'data': []});

      expect(await InstitutionService().getInstitutions(), isEmpty);
    });

    test('criar sem campos opcionais manda só o nome', () async {
      http.always(body: {'data': {}});

      await InstitutionService().createInstitution('Unifor');

      expect(http.requests.single.data, {'name': 'Unifor'});
    });

    /// RN15: o routeId no cadastro já amarra a instituição à rota que a atende.
    test('criar com rota já vincula', () async {
      http.always(body: {'data': {}});

      await InstitutionService().createInstitution(
        'Unifor',
        address: 'Av. Washington Soares',
        latitude: -3.76,
        longitude: -38.48,
        routeId: 'rota-1',
      );

      expect(http.requests.single.data, {
        'name': 'Unifor',
        'address': 'Av. Washington Soares',
        'latitude': -3.76,
        'longitude': -38.48,
        'routeId': 'rota-1',
      });
    });

    test('desvincular manda routeId nulo explicitamente', () async {
      http.always(body: {'data': {}});

      await InstitutionService().linkRoute('inst-1', null);

      expect(http.requests.single.data, {'routeId': null});
      expect(http.requests.single.method, 'PATCH');
    });

    test('editar manda só o que veio', () async {
      http.always(body: {'data': {}});

      await InstitutionService().updateInstitution('inst-1', name: 'UECE');

      expect(http.requests.single.data, {'name': 'UECE'});
    });

    test('apagar usa DELETE no id', () async {
      http.always(
        body: {
          'data': {'success': true},
        },
      );

      await InstitutionService().deleteInstitution('inst-1');

      expect(http.requests.single.method, 'DELETE');
      expect(http.requests.single.path, '/api/institutions/inst-1');
    });
  });

  group('TripService', () {
    Map<String, dynamic> statusBody({String? startedAt, String? finishedAt}) =>
        {
          'data': {
            'listId': 'lista-1',
            'routeName': 'Rota Universitária',
            'startedAt': startedAt,
            'finishedAt': finishedAt,
            'stops': [
              {
                'stopId': 'p1',
                'name': 'Rodoviária',
                'sequence': 1,
                'reachedAt': null,
              },
            ],
          },
        };

    test('status devolve o trajeto por começar', () async {
      http.always(body: statusBody());

      final t = await TripService().status('lista-1');

      expect(t.notStarted, isTrue);
      expect(t.stops, hasLength(1));
      expect(http.requests.single.path, '/api/trip/lista-1');
    });

    test('start marca o trajeto como em andamento', () async {
      http.always(body: statusBody(startedAt: '2026-09-09T06:00:00'));

      final t = await TripService().start('lista-1');

      expect(t.inProgress, isTrue);
      expect(http.requests.single.path, '/api/trip/lista-1/start');
    });

    test('checkpoint leva lista e parada na URL', () async {
      http.always(body: statusBody(startedAt: '2026-09-09T06:00:00'));

      await TripService().checkpoint('lista-1', 'p1');

      expect(http.requests.single.path, '/api/trip/lista-1/checkpoint/p1');
      expect(http.requests.single.method, 'POST');
    });

    test('finish encerra o trajeto', () async {
      http.always(
        body: statusBody(
          startedAt: '2026-09-09T06:00:00',
          finishedAt: '2026-09-09T07:30:00',
        ),
      );

      final t = await TripService().finish('lista-1');

      expect(t.finished, isTrue);
      expect(http.requests.single.path, '/api/trip/lista-1/finish');
    });
  });
}
