import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/profile/models/address_model.dart';
import 'package:smartboarding_app/features/profile/services/cep_service.dart';
import 'package:smartboarding_app/features/profile/services/profile_service.dart';
import 'package:smartboarding_app/features/profile/widgets/address_card.dart';

class _MockCepService extends Mock implements CepService {}

class _MockProfileService extends Mock implements ProfileService {}

void main() {
  late _MockCepService cep;
  late _MockProfileService profile;

  setUpAll(() => registerFallbackValue(const Address()));

  setUp(() {
    cep = _MockCepService();
    profile = _MockProfileService();
    when(
      () => profile.updateAddress(any()),
    ).thenAnswer((i) async => i.positionalArguments.first as Address);
  });

  const doViaCep = Address(
    zipCode: '35570-000',
    street: 'Av. Dr. Arnaldo de Senna',
    neighborhood: 'Água Vermelha',
    city: 'Formiga',
    state: 'MG',
  );

  Future<void> montar(WidgetTester tester, {Address? inicial}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddressCard(
              initial: inicial ?? const Address(),
              cepService: cep,
              profileService: profile,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> digitarCep(WidgetTester tester, String valor) async {
    await tester.enterText(find.byKey(const Key('address_zip_field')), valor);
    await tester.pumpAndSettle();
  }

  testWidgets('CEP preenche rua, bairro, cidade e UF', (tester) async {
    when(() => cep.lookup('35570000')).thenAnswer((_) async => doViaCep);

    await montar(tester);
    await digitarCep(tester, '35570000');

    expect(find.text('Av. Dr. Arnaldo de Senna'), findsOneWidget);
    expect(find.text('Água Vermelha'), findsOneWidget);
    expect(find.text('Formiga'), findsOneWidget);
  });

  /// O ViaCEP não tem SLA. Um CEP fora do ar não pode impedir alguém de
  /// terminar o cadastro e pegar o ônibus — os campos continuam à mão.
  testWidgets('servico fora do ar nao trava o formulario', (tester) async {
    when(() => cep.lookup(any())).thenAnswer((_) async => null);

    await montar(tester);
    await digitarCep(tester, '35570000');

    await tester.enterText(
      find.byKey(const Key('address_street_field')),
      'Rua digitada à mão',
    );
    await tester.enterText(
      find.byKey(const Key('address_neighborhood_field')),
      'Centro',
    );
    await tester.enterText(find.byKey(const Key('address_number_field')), '10');
    await tester.pump();

    await tester.tap(find.byKey(const Key('address_save_button')));
    await tester.pumpAndSettle();

    final salvo =
        verify(() => profile.updateAddress(captureAny())).captured.single
            as Address;
    expect(salvo.street, 'Rua digitada à mão');
    expect(salvo.streetNumber, '10');
  });

  /// A ordem que importa: o aluno digita à mão PRIMEIRO e o CEP falha DEPOIS.
  /// Limpar os campos nessa hora apagaria o que ele acabou de escrever.
  testWidgets('CEP que falha nao apaga o que ja foi digitado', (tester) async {
    when(() => cep.lookup(any())).thenAnswer((_) async => null);

    await montar(tester);
    await tester.enterText(
      find.byKey(const Key('address_street_field')),
      'Rua que eu sei de cor',
    );
    await tester.pump();

    await digitarCep(tester, '99999999');

    expect(find.text('Rua que eu sei de cor'), findsOneWidget);
  });

  /// O número é o único campo que o CEP não sabe. Deixar o foco parado obriga
  /// a pessoa a procurar sozinha o que faltou.
  testWidgets('foco pula pro numero depois que o CEP preenche', (tester) async {
    when(() => cep.lookup('35570000')).thenAnswer((_) async => doViaCep);

    await montar(tester);
    await digitarCep(tester, '35570000');

    final campo = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('address_number_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(campo.focusNode!.hasFocus, isTrue);
  });

  /// O que o CEP traz é chute de base pública: CEP único de cidade pequena
  /// devolve a rua errada, e travar o campo prenderia a pessoa nesse erro.
  testWidgets('campo vindo do CEP continua editavel', (tester) async {
    when(() => cep.lookup('35570000')).thenAnswer((_) async => doViaCep);

    await montar(tester);
    await digitarCep(tester, '35570000');

    await tester.enterText(
      find.byKey(const Key('address_street_field')),
      'Av. Arnaldo de Senna',
    );
    await tester.pump();

    expect(find.text('Av. Arnaldo de Senna'), findsOneWidget);
  });

  testWidgets('salva o endereco montado dos campos', (tester) async {
    when(() => cep.lookup('35570000')).thenAnswer((_) async => doViaCep);

    await montar(tester);
    await digitarCep(tester, '35570000');
    await tester.enterText(
      find.byKey(const Key('address_number_field')),
      '328',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('address_save_button')));
    await tester.pumpAndSettle();

    final salvo =
        verify(() => profile.updateAddress(captureAny())).captured.single
            as Address;
    expect(salvo.zipCode, '35570-000');
    expect(salvo.street, 'Av. Dr. Arnaldo de Senna');
    expect(salvo.neighborhood, 'Água Vermelha');
    expect(salvo.streetNumber, '328');
  });

  /// Quem já tem endereço reabre a tela e vê o que gravou, não campos vazios.
  testWidgets('reabre com o endereco que ja estava salvo', (tester) async {
    await montar(
      tester,
      inicial: const Address(
        zipCode: '35570-000',
        street: 'Av. Dr. Arnaldo de Senna',
        neighborhood: 'Água Vermelha',
        streetNumber: '328',
        complete: true,
      ),
    );

    expect(find.text('35570-000'), findsOneWidget);
    expect(find.text('328'), findsOneWidget);
  });

  /// O aviso é o que diz ao aluno por que ele não consegue entrar na lista.
  testWidgets('aponta o que falta enquanto o endereco esta incompleto', (
    tester,
  ) async {
    await montar(
      tester,
      inicial: const Address(zipCode: '35570-000', street: 'Rua A'),
    );

    // Pelo KEY do aviso, nao por find.textContaining('Bairro'): esse texto
    // tambem e o ROTULO do campo, entao o teste passava mesmo com o aviso
    // apagado. Levou uma mutacao pra aparecer.
    final aviso = find.byKey(const Key('address_missing_warning'));
    expect(aviso, findsOneWidget);

    final texto = tester
        .widget<Text>(find.descendant(of: aviso, matching: find.byType(Text)))
        .data!;
    expect(texto, contains('Falta preencher'));
    expect(texto, contains('Bairro'));
    expect(texto, contains('Número'));
    expect(texto, isNot(contains('CEP')));
    expect(texto, isNot(contains('Rua')));
  });

  testWidgets('endereco completo nao mostra aviso de pendencia', (
    tester,
  ) async {
    await montar(
      tester,
      inicial: const Address(
        zipCode: '35570-000',
        street: 'Rua A',
        neighborhood: 'Centro',
        streetNumber: '1',
        complete: true,
      ),
    );

    expect(find.byKey(const Key('address_missing_warning')), findsNothing);
  });

  /// Consultar a cada tecla seria um request por dígito, todos fadados a 404.
  testWidgets('nao consulta enquanto o CEP esta incompleto', (tester) async {
    when(() => cep.lookup(any())).thenAnswer((_) async => null);

    await montar(tester);
    await digitarCep(tester, '3557');

    verifyNever(() => cep.lookup(any()));
  });

  /// O aviso mentia: quem digitava o número à mão continuava vendo "falta
  /// preencher: Número" em vermelho e concluía que o app estava quebrado.
  /// Só o CEP reconstruía a tela, porque a busca dele já chamava setState.
  testWidgets('o aviso some enquanto o campo e digitado a mao', (tester) async {
    await montar(
      tester,
      inicial: const Address(
        zipCode: '35574-018',
        street: 'Rua Newton Garcia Cunha',
        neighborhood: 'Novo Santo Antônio',
      ),
    );
    expect(find.byKey(const Key('address_missing_warning')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('address_number_field')),
      '328',
    );
    await tester.pump();

    expect(find.byKey(const Key('address_missing_warning')), findsNothing);
  });

  /// E volta se o campo for esvaziado.
  testWidgets('apagar o campo traz o aviso de volta', (tester) async {
    await montar(
      tester,
      inicial: const Address(
        zipCode: '35574-018',
        street: 'Rua Newton Garcia Cunha',
        neighborhood: 'Novo Santo Antônio',
        streetNumber: '328',
        complete: true,
      ),
    );
    expect(find.byKey(const Key('address_missing_warning')), findsNothing);

    await tester.enterText(find.byKey(const Key('address_number_field')), '');
    await tester.pump();

    expect(find.byKey(const Key('address_missing_warning')), findsOneWidget);
  });
}
