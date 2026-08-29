import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/registration/models/institution_model.dart';
import 'package:smartboarding_app/features/registration/models/invite_info_model.dart';
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

  test('reject repassa o motivo e recarrega pendentes', () async {
    when(
      () => registrationService.reject('1', 'Documento ilegível'),
    ).thenAnswer((_) async {});
    when(
      () => registrationService.getPending(),
    ).thenAnswer((_) async => const []);

    await provider.reject('1', 'Documento ilegível');

    verify(
      () => registrationService.reject('1', 'Documento ilegível'),
    ).called(1);
    verify(() => registrationService.getPending()).called(1);
  });

  test('validateInvite guarda os dados do convite pro prefill', () async {
    when(() => registrationService.getInvite('t')).thenAnswer(
      (_) async => const InviteInfoModel(
        email: 'a@x.com',
        status: 'REJECTED',
        rejectionReason: 'Documento ilegível',
        fullName: 'Maria Oliveira',
        institutionId: 'inst-1',
      ),
    );

    await provider.validateInvite('t');

    final invite = provider.invite;
    expect(invite, isA<AsyncData<InviteInfoModel>>());
    final value = (invite as AsyncData<InviteInfoModel>).value;
    expect(value.wasRejected, isTrue);
    expect(value.rejectionReason, 'Documento ilegível');
    expect(value.fullName, 'Maria Oliveira');
  });

  test('validateInvite com token inválido vira AsyncError', () async {
    when(
      () => registrationService.getInvite('ruim'),
    ).thenThrow(Exception('expirado'));

    await provider.validateInvite('ruim');

    expect(provider.invite, isA<AsyncError>());
  });

  test('resendCode delega pro service', () async {
    when(
      () => registrationService.resendCode('a@x.com'),
    ).thenAnswer((_) async {});

    await provider.resendCode('a@x.com');

    verify(() => registrationService.resendCode('a@x.com')).called(1);
    expect(provider.resendState, isA<AsyncData>());
  });

  test('resendCode propaga erro como AsyncError', () async {
    when(
      () => registrationService.resendCode('a@x.com'),
    ).thenThrow(Exception('cooldown'));

    await provider.resendCode('a@x.com');

    expect(provider.resendState, isA<AsyncError>());
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
