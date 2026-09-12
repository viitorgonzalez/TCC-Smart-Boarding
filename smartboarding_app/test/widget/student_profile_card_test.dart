import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartboarding_app/core/theme/app_theme.dart';
import 'package:smartboarding_app/features/users/models/student_profile_model.dart';
import 'package:smartboarding_app/features/users/widgets/student_profile_card.dart';

void main() {
  final perfil = StudentProfile(
    id: 'aluno-1',
    fullName: 'Ana Oliveira',
    email: 'ana@edu.unifor.br',
    phone: '37999990000',
    address: 'Rua das Flores, 45',
    birthDate: '2004-03-12',
    course: 'Ciência da Computação',
    institution: 'UNIFOR-MG',
    isActive: false,
    role: 'STUDENT',
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

  // Decisao invertida em 09/09/2026 a pedido do autor: a ficha passou a carregar
  // contato porque o admin precisa falar com o aluno. Senha continua fora -- ela
  // nao tem uso de leitura nenhum.
  testWidgets('card mostra contato, mas nunca senha', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('@'), findsWidgets);
    expect(find.textContaining('Rua'), findsOneWidget);
    expect(find.textContaining(r'$2a$'), findsNothing);
    expect(find.textContaining('senha'), findsNothing);
  });

  testWidgets('card mostra quem mudou o status e quando', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
        ),
      ),
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
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (v) => recebido = v,
          onToggleRole: () {},
          ehAPropriaConta: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(recebido, isTrue);
  });

  testWidgets('conta inativa aparece como inativa', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: perfil,
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inativo'), findsOneWidget);
  });

  testWidgets('ficha mostra contato e nascimento formatado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentProfileBody(
            profile: perfil,
            onToggle: (_) {},
            onToggleRole: () {},
            ehAPropriaConta: false,
          ),
        ),
      ),
    );

    expect(find.text('ana@edu.unifor.br'), findsOneWidget);
    expect(find.text('37999990000'), findsOneWidget);
    expect(find.text('Rua das Flores, 45'), findsOneWidget);
    expect(find.text('12/03/2004'), findsOneWidget);
  });

  // Campo vazio some em vez de virar rotulo com travessao: linha em branco so
  // ocupa espaco e nao informa nada.
  testWidgets('campo ausente nao vira linha vazia', (tester) async {
    final semContato = StudentProfile(
      id: 'aluno-2',
      fullName: 'Bruno Silva',
      isActive: true,
      role: 'STUDENT',
      email: 'bruno@edu.unifor.br',
      phone: '   ',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentProfileBody(
            profile: semContato,
            onToggle: (_) {},
            onToggleRole: () {},
            ehAPropriaConta: false,
          ),
        ),
      ),
    );

    expect(find.text('bruno@edu.unifor.br'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byIcon(Icons.place_outlined), findsNothing);
    expect(find.byIcon(Icons.cake_outlined), findsNothing);
  });

  StudentProfile comPapel(String role, {bool ativa = true}) => StudentProfile(
    id: perfil.id,
    fullName: perfil.fullName,
    email: perfil.email,
    phone: perfil.phone,
    address: perfil.address,
    birthDate: perfil.birthDate,
    course: perfil.course,
    institution: perfil.institution,
    isActive: ativa,
    role: role,
    recentAttendance: perfil.recentAttendance,
    statusHistory: perfil.statusHistory,
  );

  /// A trava aparece como ausencia de opcao, nao como erro depois do toque: o
  /// admin nao descobre que nao podia so quando a API recusa.
  testWidgets('a propria conta nao oferece troca de papel', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('ADMIN'),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_role_action')), findsNothing);
  });

  testWidgets('conta de aluno oferece promover', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('STUDENT'),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_role_action')), findsOneWidget);
    expect(find.text('Tornar administrador'), findsOneWidget);
  });

  /// Promover conta desativada produz um admin que nao consegue entrar.
  testWidgets('conta desativada nao oferece promover', (tester) async {
    await tester.pumpWidget(
      wrap(
        StudentProfileBody(
          profile: comPapel('STUDENT', ativa: false),
          onToggle: (_) {},
          onToggleRole: () {},
          ehAPropriaConta: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('profile_role_action')),
    );
    expect(tile.enabled, isFalse);
  });
}
