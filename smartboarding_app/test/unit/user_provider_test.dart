import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/pagination/page_result.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/users/models/user_model.dart';
import 'package:smartboarding_app/features/users/providers/user_provider.dart';
import 'package:smartboarding_app/features/users/services/user_service.dart';

class _MockUserService extends Mock implements UserService {}

void main() {
  late _MockUserService service;
  late UserProvider provider;

  setUp(() {
    service = _MockUserService();
    provider = UserProvider(service);
  });

  UserModel usuario(String id, String nome) =>
      UserModel(id: id, fullName: nome, email: '\$id@x.com', role: 'STUDENT');

  test('load popula a lista de usuários', () async {
    when(() => service.getUsers(routeId: null, page: 0)).thenAnswer(
      (_) async => PageResult(items: [usuario('1', 'Ana')], hasMore: false),
    );

    await provider.load();

    expect(provider.state, isA<AsyncData<List<UserModel>>>());
    final data = provider.state as AsyncData<List<UserModel>>;
    expect(data.value.single.fullName, 'Ana');
    expect(provider.hasMore, isFalse);
  });

  /// A lista cresce sem teto: a tela pede a próxima parte ao rolar, e o que já
  /// está na tela não pode sumir no caminho.
  test('loadMore acrescenta sem perder o que ja veio', () async {
    when(() => service.getUsers(routeId: null, page: 0)).thenAnswer(
      (_) async => PageResult(items: [usuario('1', 'Ana')], hasMore: true),
    );
    when(() => service.getUsers(routeId: null, page: 1)).thenAnswer(
      (_) async => PageResult(items: [usuario('2', 'Bruno')], hasMore: false),
    );

    await provider.load();
    await provider.loadMore();

    final data = provider.state as AsyncData<List<UserModel>>;
    expect(data.value.map((u) => u.fullName), ['Ana', 'Bruno']);
    expect(provider.hasMore, isFalse);
  });

  /// Sem mais o que trazer, rolar até o fim não pode disparar requisição — a
  /// rolagem avisa a cada quadro.
  test('loadMore nao pede nada quando acabou', () async {
    when(() => service.getUsers(routeId: null, page: 0)).thenAnswer(
      (_) async => PageResult(items: [usuario('1', 'Ana')], hasMore: false),
    );

    await provider.load();
    await provider.loadMore();

    verifyNever(() => service.getUsers(routeId: null, page: 1));
  });

  /// Falhar ao buscar mais não pode apagar o que já está na tela.
  test('falha em loadMore preserva a lista', () async {
    when(() => service.getUsers(routeId: null, page: 0)).thenAnswer(
      (_) async => PageResult(items: [usuario('1', 'Ana')], hasMore: true),
    );
    when(
      () => service.getUsers(routeId: null, page: 1),
    ).thenThrow(Exception('rede'));

    await provider.load();
    await provider.loadMore();

    final data = provider.state as AsyncData<List<UserModel>>;
    expect(data.value.single.fullName, 'Ana');
  });
}
