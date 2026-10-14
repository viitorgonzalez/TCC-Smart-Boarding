import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/profile/widgets/own_data_card.dart';

void main() {
  late TextEditingController phoneCtrl;
  late TextEditingController courseCtrl;

  setUp(() {
    phoneCtrl = TextEditingController();
    courseCtrl = TextEditingController();
  });

  Future<void> montar(
    WidgetTester tester, {
    String? phone,
    String? course,
    bool aluno = true,
    bool readOnly = false,
  }) async {
    phoneCtrl.text = phone ?? '';
    courseCtrl.text = course ?? '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OwnDataCard(
              phoneCtrl: phoneCtrl,
              courseCtrl: courseCtrl,
              isStudent: aluno,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('reabre com o que ja estava salvo', (tester) async {
    await montar(tester, phone: '37999990000', course: 'Engenharia');

    expect(find.text('37999990000'), findsOneWidget);
    expect(find.text('Engenharia'), findsOneWidget);
  });

  testWidgets('curso nao aparece pro admin', (tester) async {
    await montar(tester, aluno: false);

    expect(find.byKey(const Key('own_data_course_field')), findsNothing);
    expect(find.byKey(const Key('own_data_phone_field')), findsOneWidget);
  });

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

  testWidgets('curso vazio nao gera aviso', (tester) async {
    await montar(tester, phone: '37999990000', course: null);

    expect(find.byKey(const Key('own_data_missing_warning')), findsNothing);
  });

  testWidgets('readOnly trava os campos', (tester) async {
    await montar(tester, phone: '37999990000', readOnly: true);

    await tester.enterText(
      find.byKey(const Key('own_data_phone_field')),
      '37900000000',
    );
    await tester.pump();

    expect(phoneCtrl.text, '37999990000');
  });
}
