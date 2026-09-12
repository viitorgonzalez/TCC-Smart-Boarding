import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/features/users/models/user_model.dart';
import 'package:smartboarding_app/features/users/providers/user_provider.dart';
import 'package:smartboarding_app/features/users/services/user_service.dart';
import 'package:smartboarding_app/features/users/widgets/user_tile.dart';

import '../support/fake_http.dart';
import '../support/pump_until.dart';

/// A linha da lista abre a ficha. O que precisa de rede aqui é o caminho de
/// volta: a ficha só atualiza o estado dela, então quem abriu tem que recarregar
/// a própria lista — senão o aluno recém-promovido continua no grupo "Alunos"
/// com a etiqueta antiga até um pull-to-refresh.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const aluno = UserModel(
    id: 'aluno-1',
    fullName: 'Ana Oliveira',
    email: 'ana@edu.unifor.br',
    role: 'STUDENT',
  );

  Future<FakeHttpAdapter> montarLista(
    WidgetTester tester,
    UserProvider provider,
  ) async {
    // A ficha é mais alta que a janela padrão de teste (800x600): aberta
    // inteira, o conteúdo estouraria o viewport e o tap na ação de papel não
    // acharia alvo.
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on('GET', '/api/users', body: {
      'data': [
        {
          'id': aluno.id,
          'fullName': aluno.fullName,
          'email': aluno.email,
          'role': aluno.role,
        },
      ],
    });
    http.on('GET', '/api/users/admins/count', body: {
      'data': {'count': 2},
    });
    http.on('GET', '/api/users/aluno-1/profile', body: {
      'data': {
        'id': 'aluno-1',
        'fullName': 'Ana Oliveira',
        'email': 'ana@edu.unifor.br',
        'isActive': true,
        'role': 'STUDENT',
        'recentAttendance': [],
        'statusHistory': [],
      },
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: UserTile(user: aluno)),
        ),
      ),
    );
    return http;
  }

  /// Abre a folha e espera a ficha aparecer — as buscas do `initState` só andam
  /// intercalando tempo real e relógio falso, por isso o `pumpUntil`.
  Future<void> abrirFicha(WidgetTester tester) async {
    await tester.tap(find.byType(ListTile));
    await pumpUntil(
      tester,
      () => find.byKey(const Key('profile_role_action')).evaluate().isNotEmpty,
      describe: 'a ficha do usuário carregar',
    );
    // A folha entra deslizando de baixo. Enquanto a animação não termina o
    // conteúdo está montado mas posicionado fora da tela, e o tap não acerta
    // alvo nenhum.
    await tester.pumpAndSettle();
  }

  testWidgets('promover pela ficha recarrega a lista de trás', (tester) async {
    final provider = UserProvider(UserService());
    final http = await montarLista(tester, provider);
    http.on('PATCH', '/api/users/aluno-1/role', body: {
      'data': {
        'id': 'aluno-1',
        'fullName': 'Ana Oliveira',
        'email': 'ana@edu.unifor.br',
        'isActive': true,
        'role': 'ADMIN',
        'recentAttendance': [],
        'statusHistory': [],
      },
    });

    await abrirFicha(tester);
    await tester.tap(find.byKey(const Key('profile_role_action')));
    await pumpUntil(
      tester,
      () => http.requests.any((r) => r.method == 'PATCH'),
      describe: 'o PATCH de papel',
    );

    // A recarga só dispara quando a folha fecha: showStudentProfile espera a
    // rota modal sair antes de devolver o veredito.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await pumpUntil(
      tester,
      () => http.requests.where((r) => r.path == '/api/users').isNotEmpty,
      describe: 'a lista recarregar',
    );

    expect(http.requests.where((r) => r.path == '/api/users'), hasLength(1));
  });

  /// Fechar a folha sem mexer em nada não pode custar uma requisição: a folha
  /// abre de três telas e é o gesto mais comum da lista.
  testWidgets('fechar a ficha sem mudar nada não recarrega', (tester) async {
    final provider = UserProvider(UserService());
    final http = await montarLista(tester, provider);

    await abrirFicha(tester);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await pumpUntil(
      tester,
      () => find.byKey(const Key('profile_role_action')).evaluate().isEmpty,
      describe: 'a ficha fechar',
    );

    expect(http.requests.where((r) => r.path == '/api/users'), isEmpty);
  });
}
