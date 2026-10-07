import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/profile/models/address_model.dart';
import 'package:smartboarding_app/features/profile/services/cep_service.dart';
import 'package:smartboarding_app/features/profile/widgets/address_card.dart';

class _MockCepService extends Mock implements CepService {}

void main() {
  late _MockCepService cep;
  late TextEditingController cepCtrl;
  late TextEditingController ruaCtrl;
  late TextEditingController bairroCtrl;
  late TextEditingController cidadeCtrl;
  late TextEditingController ufCtrl;
  late TextEditingController numeroCtrl;
  late TextEditingController complementoCtrl;

  setUp(() {
    cep = _MockCepService();
    cepCtrl = TextEditingController();
    ruaCtrl = TextEditingController();
    bairroCtrl = TextEditingController();
    cidadeCtrl = TextEditingController();
    ufCtrl = TextEditingController();
    numeroCtrl = TextEditingController();
    complementoCtrl = TextEditingController();
  });

  const doViaCep = Address(
    zipCode: '35570-000',
    street: 'Av. Dr. Arnaldo de Senna',
    neighborhood: 'Água Vermelha',
    city: 'Formiga',
    state: 'MG',
  );

  Future<void> montar(WidgetTester tester, {Address? inicial}) async {
    final i = inicial ?? const Address();
    cepCtrl.text = i.zipCode ?? '';
    ruaCtrl.text = i.street ?? '';
    bairroCtrl.text = i.neighborhood ?? '';
    cidadeCtrl.text = i.city ?? '';
    ufCtrl.text = i.state ?? '';
    numeroCtrl.text = i.streetNumber ?? '';
    complementoCtrl.text = i.complement ?? '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddressCard(
              cepCtrl: cepCtrl,
              ruaCtrl: ruaCtrl,
              bairroCtrl: bairroCtrl,
              cidadeCtrl: cidadeCtrl,
              ufCtrl: ufCtrl,
              numeroCtrl: numeroCtrl,
              complementoCtrl: complementoCtrl,
              cepService: cep,
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

    expect(ruaCtrl.text, 'Rua digitada à mão');
    expect(numeroCtrl.text, '10');
  });

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

  testWidgets('aponta o que falta enquanto o endereco esta incompleto', (
    tester,
  ) async {
    await montar(
      tester,
      inicial: const Address(zipCode: '35570-000', street: 'Rua A'),
    );

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

  testWidgets('nao consulta enquanto o CEP esta incompleto', (tester) async {
    when(() => cep.lookup(any())).thenAnswer((_) async => null);

    await montar(tester);
    await digitarCep(tester, '3557');

    verifyNever(() => cep.lookup(any()));
  });

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

  testWidgets('readOnly trava os campos', (tester) async {
    await montar(
      tester,
      inicial: const Address(street: 'Rua A', complete: true),
    );
    cepCtrl.text = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddressCard(
              cepCtrl: cepCtrl,
              ruaCtrl: ruaCtrl,
              bairroCtrl: bairroCtrl,
              cidadeCtrl: cidadeCtrl,
              ufCtrl: ufCtrl,
              numeroCtrl: numeroCtrl,
              complementoCtrl: complementoCtrl,
              cepService: cep,
              readOnly: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('address_street_field')),
      'Outra rua',
    );
    await tester.pump();

    expect(ruaCtrl.text, 'Rua A');
  });
}
