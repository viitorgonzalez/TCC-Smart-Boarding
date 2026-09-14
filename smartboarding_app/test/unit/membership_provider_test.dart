import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/membership/providers/membership_provider.dart';

import '../support/fake_http.dart';

Map<String, dynamic> rota(String id, String nome) => {
  'id': id,
  'name': nome,
  'isActive': true,
  'createdAt': '2026-09-01T10:00:00',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHttpAdapter http;
  late MembershipProvider provider;

  setUp(() async {
    http = await installFakeHttp();
    provider = MembershipProvider();
  });

  test('aluno sem rota cai no estado vazio', () async {
    http.on('GET', '/api/me/routes', body: {'data': []});

    await provider.load();

    expect(provider.hasNoRoute, isTrue);
    expect(provider.selected, isNull);
  });

  test('com uma rota ela ja vem selecionada', () async {
    http.on(
      'GET',
      '/api/me/routes',
      body: {
        'data': [rota('r1', 'Rota Universitária')],
      },
    );

    await provider.load();

    expect(provider.hasNoRoute, isFalse);
    expect(provider.selected?.name, 'Rota Universitária');
  });

  test('com varias rotas a primeira fica em foco e da pra trocar', () async {
    http.on(
      'GET',
      '/api/me/routes',
      body: {
        'data': [rota('r1', 'Rota A'), rota('r2', 'Rota B')],
      },
    );

    await provider.load();
    expect(provider.selected?.id, 'r1');

    provider.select('r2');
    expect(provider.selected?.id, 'r2');
  });

  test('entrar com codigo poe a rota nova em foco', () async {
    http.on('GET', '/api/me/routes', body: {'data': []});
    await provider.load();

    http.on('POST', '/api/me/routes', body: {'data': rota('r9', 'Rota Nova')});
    http.on(
      'GET',
      '/api/me/routes',
      body: {
        'data': [rota('r1', 'Rota A'), rota('r9', 'Rota Nova')],
      },
    );

    final entrou = await provider.join('RU7K2M');

    expect(entrou.name, 'Rota Nova');
    // Entrar numa rota e um ato deliberado: deixar o foco na antiga faria o
    // aluno achar que o codigo nao funcionou.
    expect(provider.selected?.id, 'r9');
  });

  // Sair da rota que estava em foco nao pode deixar o id orfao: a home ficaria
  // pedindo dado de uma rota que o aluno nao tem mais.
  test('sair da rota em foco reposiciona a selecao', () async {
    http.on(
      'GET',
      '/api/me/routes',
      body: {
        'data': [rota('r1', 'Rota A'), rota('r2', 'Rota B')],
      },
    );
    await provider.load();
    provider.select('r2');

    // Sobrescreve o GET explicitamente: o adaptador da prioridade a rota ja
    // registrada, entao `always` sozinho nao substituiria a resposta anterior.
    http.on(
      'DELETE',
      '/api/me/routes/r2',
      body: {
        'data': {'success': true},
      },
    );
    http.on(
      'GET',
      '/api/me/routes',
      body: {
        'data': [rota('r1', 'Rota A')],
      },
    );
    await provider.leave('r2');

    expect(provider.selected?.id, 'r1');
    expect(provider.routes, hasLength(1));
  });

  test('codigo invalido propaga o erro pra tela decidir a mensagem', () async {
    http.on('GET', '/api/me/routes', body: {'data': []});
    await provider.load();
    http.on(
      'POST',
      '/api/me/routes',
      status: 400,
      body: {'code': 'CODE_EXPIRED', 'error': 'Esse código expirou.'},
    );

    await expectLater(provider.join('RU7K2M'), throwsA(anything));
  });

  test('falha ao carregar nao mente dizendo que nao ha rota', () async {
    http.on('GET', '/api/me/routes', status: 500, body: {'error': 'boom'});

    await provider.load();

    // hasNoRoute falso no erro e proposital: mostrar "entre com codigo" quando
    // na verdade a rede caiu mandaria o aluno resolver o problema errado.
    expect(provider.hasNoRoute, isFalse);
    expect(provider.routes, isEmpty);
  });
}
