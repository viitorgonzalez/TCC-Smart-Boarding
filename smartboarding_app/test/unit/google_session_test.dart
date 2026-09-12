import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/services/storage_service.dart';
import 'package:smartboarding_app/features/auth/services/auth_service.dart';
import 'package:smartboarding_app/features/lists/providers/student_list_provider.dart';
import 'package:smartboarding_app/features/lists/services/list_service.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Quem entra pelo Google nunca digita o e-mail. Se a sessao nao trouxer, o
  /// app fica sem saber de quem carregar a lista do dia -- e a home girava pra
  /// sempre, sem erro nenhum na tela.
  test('sessao do Google guarda o e-mail que veio da API', () async {
    final http = await installFakeHttp();
    http.on(
      'POST',
      '/api/auth/google',
      body: {
        'data': {
          'token': 'jwt-google',
          'fullName': 'Vitor Pastor',
          'role': 'STUDENT',
          'email': 'vitor@gmail.com',
        },
      },
    );

    final sessao = await AuthService().signInWithGoogle('id-token');

    expect(sessao.email, 'vitor@gmail.com');
    expect(await StorageService().getEmail(), 'vitor@gmail.com');
  });

  test('login por senha prefere o e-mail da API ao digitado', () async {
    final http = await installFakeHttp();
    http.on(
      'POST',
      '/api/auth/login',
      body: {
        'data': {
          'token': 'jwt',
          'fullName': 'Vitor Pastor',
          'role': 'STUDENT',
          'email': 'vitor@gmail.com',
        },
      },
    );

    final sessao = await AuthService().login('VITOR@gmail.com', 'segredo123');

    expect(sessao.email, 'vitor@gmail.com');
  });

  /// API antiga, que ainda nao manda o campo: o digitado segura o fluxo.
  test('sem e-mail na resposta, o digitado vale', () async {
    final http = await installFakeHttp();
    http.on(
      'POST',
      '/api/auth/login',
      body: {
        'data': {'token': 'jwt', 'fullName': 'Vitor', 'role': 'STUDENT'},
      },
    );

    final sessao = await AuthService().login('vitor@gmail.com', 'segredo123');

    expect(sessao.email, 'vitor@gmail.com');
  });

  /// O pior sintoma possivel e o silencioso: carregar pra sempre nao diz nada
  /// ao aluno e nao aparece em log nenhum.
  test(
    'sessao sem e-mail vira erro na tela, nao carregamento eterno',
    () async {
      await installFakeHttp();
      final provider = StudentListProvider(ListService());

      await provider.load();

      expect(provider.state, isA<AsyncError>());
      expect(
        (provider.state as AsyncError).message,
        contains('Entre novamente'),
      );
    },
  );
}
