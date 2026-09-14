import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/institutions/providers/institution_provider.dart';

import '../support/fake_http.dart';

Map<String, dynamic> inst(String id, String nome, {String? routeId}) => {
  'id': id,
  'name': nome,
  'routeId': routeId,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;
  late InstitutionProvider provider;

  setUp(() async {
    http = await installFakeHttp();
    provider = InstitutionProvider();
  });

  test('carrega o catalogo inteiro', () async {
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [inst('i1', 'Unifor', routeId: 'r1'), inst('i2', 'UECE')],
      },
    );

    await provider.load();

    expect(provider.all, hasLength(2));
  });

  /// A tela da rota so oferece instituicao SEM rota: listar as ja vinculadas
  /// convidaria a roubar de outra rota sem que ninguem percebesse.
  test('unlinked traz so as que nao tem rota', () async {
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [
          inst('i1', 'Unifor', routeId: 'r1'),
          inst('i2', 'UECE'),
          inst('i3', 'IFMG'),
        ],
      },
    );

    await provider.load();

    expect(provider.unlinked.map((i) => i.name), ['UECE', 'IFMG']);
  });

  test('servedBy filtra pela rota', () async {
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [
          inst('i1', 'Unifor', routeId: 'r1'),
          inst('i2', 'UECE', routeId: 'r2'),
          inst('i3', 'IFMG', routeId: 'r1'),
        ],
      },
    );

    await provider.load();

    expect(provider.servedBy('r1').map((i) => i.name), ['Unifor', 'IFMG']);
    expect(provider.servedBy('r9'), isEmpty);
  });

  test('vincular recarrega o catalogo', () async {
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [inst('i2', 'UECE')],
      },
    );
    await provider.load();
    expect(provider.unlinked, hasLength(1));

    http.on('PATCH', '/api/institutions/i2/route', body: {'data': {}});
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [inst('i2', 'UECE', routeId: 'r1')],
      },
    );
    await provider.linkRoute('i2', 'r1');

    // Sem recarregar, a tela continuaria oferecendo a instituicao que acabou de
    // ser vinculada.
    expect(provider.unlinked, isEmpty);
    expect(provider.servedBy('r1'), hasLength(1));
  });

  test('desvincular manda routeId nulo e devolve ao catalogo', () async {
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [inst('i1', 'Unifor', routeId: 'r1')],
      },
    );
    await provider.load();

    http.on('PATCH', '/api/institutions/i1/route', body: {'data': {}});
    http.on(
      'GET',
      '/api/institutions',
      body: {
        'data': [inst('i1', 'Unifor')],
      },
    );
    await provider.linkRoute('i1', null);

    expect(provider.unlinked, hasLength(1));
    final patch = http.requests.firstWhere((r) => r.method == 'PATCH');
    expect(patch.data, {'routeId': null});
  });

  test('falha ao carregar nao finge catalogo vazio', () async {
    http.on('GET', '/api/institutions', status: 500, body: {'error': 'boom'});

    await provider.load();

    expect(provider.all, isEmpty);
    expect(provider.state, isA<AsyncError>());
  });
}
