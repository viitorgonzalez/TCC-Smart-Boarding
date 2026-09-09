import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/users/models/student_profile_model.dart';
import 'package:smartboarding_app/features/users/widgets/student_profile_card.dart';

void main() {
  final perfil = StudentProfile(
    id: 'aluno-1',
    fullName: 'Ana Oliveira',
    course: 'Ciência da Computação',
    institution: 'UNIFOR-MG',
    isActive: false,
    recentAttendance: const ['2026-09-01', '2026-09-02'],
    statusHistory: const [
      StatusChange(
        action: 'DEACTIVATED',
        adminName: 'System Administrator',
        at: '2026-09-08T14:00:00',
      ),
    ],
  );

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('card não mostra e-mail nem endereço', (tester) async {
    await tester.pumpWidget(
      wrap(StudentProfileBody(profile: perfil, onToggle: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('Rua'), findsNothing);
  });

  testWidgets('card mostra quem mudou o status e quando', (tester) async {
    await tester.pumpWidget(
      wrap(StudentProfileBody(profile: perfil, onToggle: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Desativado por System Administrator'),
      findsOneWidget,
    );
  });

  testWidgets('alternar o switch avisa quem abriu o card', (tester) async {
    bool? recebido;
    await tester.pumpWidget(
      wrap(StudentProfileBody(profile: perfil, onToggle: (v) => recebido = v)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(recebido, isTrue);
  });

  testWidgets('conta inativa aparece como inativa', (tester) async {
    await tester.pumpWidget(
      wrap(StudentProfileBody(profile: perfil, onToggle: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inativo'), findsOneWidget);
  });
}
