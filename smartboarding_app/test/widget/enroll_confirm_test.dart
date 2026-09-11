import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/features/lists/widgets/enroll_student_sheet.dart';
import 'package:smartboarding_app/features/users/models/user_model.dart';

final _aluno = UserModel(
  id: 'aluno-1',
  fullName: 'Fernanda Lima',
  email: 'fernanda@edu.unifor.br',
  role: 'STUDENT',
);

Future<bool?> _abrir(WidgetTester tester, EnrollDecision decision) async {
  bool? resultado;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              resultado = await confirmEnroll(context, _aluno, decision);
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

void main() {
  testWidgets('confirmação diz que a advertência vai pro histórico', (
    tester,
  ) async {
    await _abrir(tester, const EnrollDecision(issueWarning: true));

    expect(find.text('Incluir Fernanda Lima?'), findsOneWidget);
    expect(
      find.text('Uma advertência vai para o histórico do aluno.'),
      findsOneWidget,
    );
  });

  testWidgets('sem advertência o texto muda', (tester) async {
    await _abrir(tester, const EnrollDecision(issueWarning: false));

    expect(find.text('Nenhuma advertência será gerada.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('motivo informado aparece na confirmação', (tester) async {
    await _abrir(
      tester,
      const EnrollDecision(issueWarning: true, reason: 'Esqueceu de entrar'),
    );

    expect(find.text('Motivo: Esqueceu de entrar'), findsOneWidget);
  });

  // Cancelar tem que devolver false: um retorno nulo tratado como sucesso
  // incluiria o aluno sem o admin ter confirmado.
  testWidgets('cancelar devolve false', (tester) async {
    await _abrir(tester, const EnrollDecision(issueWarning: true));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Incluir Fernanda Lima?'), findsNothing);
  });

  testWidgets('confirmar fecha o diálogo', (tester) async {
    await _abrir(tester, const EnrollDecision(issueWarning: true));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Incluir Fernanda Lima?'), findsNothing);
  });
}
