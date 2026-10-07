import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/routes/providers/route_provider.dart';
import 'package:smartboarding_app/features/routes/services/route_service.dart';

import '../support/fake_http.dart';

Map<String, dynamic> rota(String id, String nome) => {
  'id': id,
  'name': nome,
  'isActive': true,
  'createdAt': '2026-01-01T00:00:00',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;
  late RouteProvider provider;

  setUp(() async {
    http = await installFakeHttp();
    provider = RouteProvider(RouteService());
  });

  test('primeira carga passa por AsyncLoading', () async {
    http.on('GET', '/api/routes', body: {'data': [rota('r1', 'Rota A')]});

    expect(provider.state, isA<AsyncLoading<List<dynamic>>>());
    await provider.load();

    expect(provider.state, isA<AsyncData<List<dynamic>>>());
  });

  test('recarregar depois da primeira carga nao volta pra AsyncLoading', () async {
    http.on('GET', '/api/routes', body: {'data': [rota('r1', 'Rota A')]});
    await provider.load();
    expect(provider.state, isA<AsyncData<List<dynamic>>>());

    final estados = <AsyncValue<List<dynamic>>>[];
    provider.addListener(() => estados.add(provider.state));

    http.on('GET', '/api/routes', body: {
      'data': [rota('r1', 'Rota A'), rota('r2', 'Rota B')],
    });
    await provider.load();

    expect(estados, everyElement(isA<AsyncData<List<dynamic>>>()));
  });

  test('update recarrega sem passar por AsyncLoading', () async {
    http.on('GET', '/api/routes', body: {'data': [rota('r1', 'Rota A')]});
    await provider.load();

    final estados = <AsyncValue<List<dynamic>>>[];
    provider.addListener(() => estados.add(provider.state));

    http.on('PATCH', '/api/routes/r1', body: {'data': rota('r1', 'Rota A Editada')});
    http.on('GET', '/api/routes', body: {
      'data': [rota('r1', 'Rota A Editada')],
    });
    await provider.update('r1', 'Rota A Editada', null);

    expect(estados, everyElement(isA<AsyncData<List<dynamic>>>()));
  });
}
