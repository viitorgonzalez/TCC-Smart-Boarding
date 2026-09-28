import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/models/address_model.dart';
import 'package:smartboarding_app/features/profile/models/profile_update_model.dart';
import 'package:smartboarding_app/features/profile/screens/student_card_screen.dart';

void main() {
  const enderecoCompleto = Address(
    zipCode: '35570-000',
    street: 'Av. Dr. Arnaldo de Senna',
    neighborhood: 'Água Vermelha',
    city: 'Formiga',
    state: 'MG',
    streetNumber: '328',
    complete: true,
    shortForm: 'Av. Dr. Arnaldo de Senna, 328 — Água Vermelha',
  );

  Me aluno({
    Address address = enderecoCompleto,
    String? institution = 'UNIFOR-MG — Formiga',
    String? course = 'Engenharia de Software',
    List<String> faltando = const [],
  }) => Me(
    id: 'u1',
    fullName: 'Fernanda Lima Souza',
    email: 'fernanda@edu.unifor.br',
    role: 'STUDENT',
    hasPassword: true,
    hasGoogle: false,
    course: course,
    address: address,
    institution: institution,
    missingForList: faltando,
  );

  Future<void> montar(
    WidgetTester tester, {
    Me? me,
    bool comRota = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentCardScreen(me: me ?? aluno(), hasActiveRoute: comRota),
      ),
    );
    await tester.pump();
  }

  String todoOTexto(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .join(' | ');

  testWidgets('mostra nome, instituicao e curso', (tester) async {
    await montar(tester);

    expect(find.text('Fernanda Lima Souza'), findsOneWidget);
    expect(find.text('UNIFOR-MG — Formiga'), findsOneWidget);
    expect(find.text('Engenharia de Software'), findsOneWidget);
  });

  testWidgets('mostra rua, numero e bairro', (tester) async {
    await montar(tester);

    expect(
      find.text('Av. Dr. Arnaldo de Senna, 328 — Água Vermelha'),
      findsOneWidget,
    );
  });

  /// A carteirinha se mostra pra outra pessoa. CEP e cidade não ajudam numa
  /// conferência presencial e não precisam circular numa tela dessas.
  testWidgets('nao expoe CEP, cidade nem e-mail', (tester) async {
    await montar(tester);

    final texto = todoOTexto(tester);
    expect(texto, isNot(contains('35570')));
    expect(texto, isNot(contains('Formiga,')));
    expect(texto, isNot(contains('fernanda@edu.unifor.br')));
  });

  /// Carteirinha com lacuna não serve pra conferência nenhuma: melhor dizer o
  /// que falta do que entregar um documento pela metade.
  testWidgets('perfil incompleto mostra o que falta em vez do cartao', (
    tester,
  ) async {
    await montar(
      tester,
      me: aluno(address: const Address(), faltando: const ['address']),
    );

    expect(find.byKey(const Key('student_card_incomplete')), findsOneWidget);
    expect(find.byKey(const Key('student_card_body')), findsNothing);
  });

  /// A validade é o vínculo ativo: é isso que a carteirinha atesta.
  testWidgets('sem rota ativa a carteirinha nao vale', (tester) async {
    await montar(tester, comRota: false);

    expect(find.byKey(const Key('student_card_no_route')), findsOneWidget);
    expect(find.byKey(const Key('student_card_body')), findsNothing);
  });

  /// Sem isso vira documento com aparência de oficial que ninguém auditou: o
  /// app sabe o que o aluno declarou, não valida vínculo com a instituição.
  testWidgets('diz que nao e documento oficial', (tester) async {
    await montar(tester);

    expect(todoOTexto(tester).toLowerCase(), contains('não é documento'));
  });

  testWidgets('curso vazio nao deixa rotulo orfao', (tester) async {
    await montar(tester, me: aluno(course: null));

    expect(find.text('Curso'), findsNothing);
  });

  testWidgets('sem instituicao nao deixa rotulo orfao', (tester) async {
    await montar(tester, me: aluno(institution: null));

    expect(find.text('Instituição'), findsNothing);
  });
}
