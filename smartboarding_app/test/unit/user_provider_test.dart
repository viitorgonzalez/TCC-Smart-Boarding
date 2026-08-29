import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test('load popula a lista de usuários', () async {
    when(() => service.getUsers()).thenAnswer(
      (_) async => const [
        UserModel(id: '1', fullName: 'Ana', email: 'a@x.com', role: 'STUDENT'),
      ],
    );

    await provider.load();

    expect(provider.state, isA<AsyncData<List<UserModel>>>());
    final data = provider.state as AsyncData<List<UserModel>>;
    expect(data.value.single.fullName, 'Ana');
  });

  test('create chama register e recarrega a lista', () async {
    when(
      () => service.register(
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        role: any(named: 'role'),
      ),
    ).thenAnswer((_) async {});
    when(() => service.getUsers()).thenAnswer((_) async => const []);

    await provider.create(
      fullName: 'João',
      email: 'j@x.com',
      password: '123456',
      role: 'DRIVER',
    );

    verify(
      () => service.register(
        fullName: 'João',
        email: 'j@x.com',
        password: '123456',
        role: 'DRIVER',
      ),
    ).called(1);
    verify(() => service.getUsers()).called(1);
  });
}
