import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/features/profile/services/profile_service.dart';
import 'package:smartboarding_app/features/profile/widgets/own_data_card.dart';

class _MockProfileService extends Mock implements ProfileService {}

void main() {
  late _MockProfileService profile;

  setUp(() {
    profile = _MockProfileService();
    when(
      () => profile.updateOwnProfile(
        phone: any(named: 'phone'),
        course: any(named: 'course'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> montar(
    WidgetTester tester, {
    String? phone,
    String? course,
    bool aluno = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OwnDataCard(
              phone: phone,
              course: course,
              isStudent: aluno,
              service: profile,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> salvar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('own_data_save_button')));
    await tester.pumpAndSettle();
  }

  /// O ponto da mudança: telefone é pré-requisito pra entrar na lista, e
  /// esperar aprovação pra preenchê-lo custaria a viagem de amanhã.
  testWidgets('telefone salva direto, sem abrir solicitacao', (tester) async {
    await montar(tester);

    await tester.enterText(
      find.byKey(const Key('own_data_phone_field')),
      '37988887777',
    );
    await salvar(tester);

    verify(
      () => profile.updateOwnProfile(phone: '37988887777', course: any(named: 'course')),
    ).called(1);
    verifyNever(
      () => profile.requestUpdate(
        fullName: any(named: 'fullName'),
        institutionId: any(named: 'institutionId'),
        birthDate: any(named: 'birthDate'),
      ),
    );
  });

  testWidgets('reabre com o que ja estava salvo', (tester) async {
    await montar(tester, phone: '37999990000', course: 'Engenharia');

    expect(find.text('37999990000'), findsOneWidget);
    expect(find.text('Engenharia'), findsOneWidget);
  });

  /// Curso descreve quem estuda. Quem administra declara instituição pra
  /// vincular a rota, e mais nada.
  testWidgets('curso nao aparece pro admin', (tester) async {
    await montar(tester, aluno: false);

    expect(find.byKey(const Key('own_data_course_field')), findsNothing);
    expect(find.byKey(const Key('own_data_phone_field')), findsOneWidget);
  });

  /// O campo nem aparece pro admin, mas o controller nasce com o valor que
  /// vier do /me. Uma conta que já foi de aluno carrega curso, e mandá-lo aqui
  /// regravaria dado de um papel que ela não tem mais.
  testWidgets('admin com curso herdado nao reenvia o curso', (tester) async {
    await montar(
      tester,
      aluno: false,
      phone: '37999990000',
      course: 'Engenharia',
    );

    await salvar(tester);

    verify(
      () => profile.updateOwnProfile(phone: '37999990000', course: null),
    ).called(1);
  });

  /// Sem telefone o aluno não entra na lista: o card precisa dizer isso antes
  /// de ele descobrir esbarrando no botão da lista.
  testWidgets('avisa quando o telefone esta em branco', (tester) async {
    await montar(tester);

    final aviso = find.byKey(const Key('own_data_missing_warning'));
    expect(aviso, findsOneWidget);
    expect(
      tester
          .widget<Text>(find.descendant(of: aviso, matching: find.byType(Text)))
          .data!,
      contains('Telefone'),
    );
  });

  testWidgets('com telefone preenchido nao ha aviso', (tester) async {
    await montar(tester, phone: '37999990000');

    expect(find.byKey(const Key('own_data_missing_warning')), findsNothing);
  });

  /// Curso é opcional: travar por ele tiraria alguém do ônibus por um campo
  /// que ninguém usa no dia da viagem.
  testWidgets('curso vazio nao gera aviso', (tester) async {
    await montar(tester, phone: '37999990000', course: null);

    expect(find.byKey(const Key('own_data_missing_warning')), findsNothing);
  });
}
