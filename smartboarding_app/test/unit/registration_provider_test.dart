import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/registration/models/institution_model.dart';
import 'package:smartboarding_app/features/registration/models/registration_request_model.dart';
import 'package:smartboarding_app/features/registration/providers/registration_provider.dart';
import 'package:smartboarding_app/features/registration/services/institution_service.dart';
import 'package:smartboarding_app/features/registration/services/registration_service.dart';

class _MockRegistrationService extends Mock implements RegistrationService {}

class _MockInstitutionService extends Mock implements InstitutionService {}

void main() {
  late _MockRegistrationService registrationService;
  late _MockInstitutionService institutionService;
  late RegistrationProvider provider;

  setUp(() {
    registrationService = _MockRegistrationService();
    institutionService = _MockInstitutionService();
    provider = RegistrationProvider(registrationService, institutionService);
  });

  test('loadInstitutions popula a lista', () async {
    when(() => institutionService.getInstitutions()).thenAnswer(
      (_) async => const [InstitutionModel(id: '1', name: 'Unifor')],
    );

    await provider.loadInstitutions();

    expect(provider.institutions, isA<AsyncData<List<InstitutionModel>>>());
  });

  test('loadPending popula a lista de pendentes', () async {
    when(() => registrationService.getPending()).thenAnswer(
      (_) async => const [
        RegistrationRequestModel(
          id: '1',
          email: 'a@x.com',
          createdAt: '2026-08-20',
        ),
      ],
    );

    await provider.loadPending();

    expect(provider.pending, isA<AsyncData<List<RegistrationRequestModel>>>());
  });

  test('approve chama o service e recarrega pendentes', () async {
    when(() => registrationService.approve('1')).thenAnswer((_) async {});
    when(
      () => registrationService.getPending(),
    ).thenAnswer((_) async => const []);

    await provider.approve('1');

    verify(() => registrationService.approve('1')).called(1);
    verify(() => registrationService.getPending()).called(1);
  });

  test('reject chama o service e recarrega pendentes', () async {
    when(() => registrationService.reject('1')).thenAnswer((_) async {});
    when(
      () => registrationService.getPending(),
    ).thenAnswer((_) async => const []);

    await provider.reject('1');

    verify(() => registrationService.reject('1')).called(1);
    verify(() => registrationService.getPending()).called(1);
  });

  test('submit propaga erro como AppException legível', () async {
    when(
      () => registrationService.submit(
        token: any(named: 'token'),
        fullName: any(named: 'fullName'),
        password: any(named: 'password'),
        institutionId: any(named: 'institutionId'),
        course: any(named: 'course'),
        phone: any(named: 'phone'),
        address: any(named: 'address'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenThrow(Exception('falhou'));

    await provider.submit(
      token: 't',
      fullName: 'Maria',
      password: '123456',
      institutionId: 'inst-1',
    );

    expect(provider.submitState, isA<AsyncError>());
  });
}
