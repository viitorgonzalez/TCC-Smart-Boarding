import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/services/profile_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// O admin e obrigado a escrever o motivo da recusa justamente pro aluno ler
  /// e corrigir. A tela lia /pending, que so devolve PENDING -- entao a recusa
  /// nunca chegava: o formulario simplesmente destravava sem explicacao.
  test('a recusa e o motivo chegam ao aluno', () async {
    final http = await installFakeHttp(token: 'jwt');
    http.on(
      'GET',
      '/api/me/profile-requests/latest',
      body: {
        'data': {
          'id': 'pedido-1',
          'userId': 'aluno-1',
          'studentName': 'Fernanda Lima',
          'status': 'REJECTED',
          'rejectionReason': 'Curso não confere com a matrícula',
          'createdAt': '2026-09-12T10:00:00',
        },
      },
    );

    final pedido = await ProfileService().myLatest();

    expect(pedido, isNotNull);
    expect(pedido!.rejected, isTrue);
    expect(pedido.rejectionReason, contains('Curso não confere'));
  });

  test('sem pedido nenhum devolve null, nao quebra', () async {
    final http = await installFakeHttp(token: 'jwt');
    http.on('GET', '/api/me/profile-requests/latest', body: {'data': null});

    expect(await ProfileService().myLatest(), isNull);
  });
}
