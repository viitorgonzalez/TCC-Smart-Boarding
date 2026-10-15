import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/core/providers/auth_provider.dart';
import 'package:smartboarding_app/core/widgets/trip_type_chip.dart';
import 'package:smartboarding_app/features/lists/models/daily_list_model.dart';
import 'package:smartboarding_app/features/lists/screens/admin_list_entries_screen.dart';
import 'package:smartboarding_app/features/users/widgets/student_profile_card.dart';

import '../support/fake_http.dart';

const _userId = 'u-1';

Future<void> abrirInscritos(WidgetTester tester) async {
  final http = await installFakeHttp(token: 'jwt-de-teste');
  http.on(
    'GET',
    '/api/lists/l1/entries',
    body: {
      'data': [
        {
          'id': 'e1',
          'userId': _userId,
          'fullName': 'Fernanda Costa',
          'email': 'fernanda@student.com',
          'institutionName': 'UNIFOR-MG',
          'tripType': 'ROUND_TRIP',
          'createdAt': '2026-10-14T18:49:31',
          'addedByAdmin': false,
        },
      ],
    },
  );
  http.always(body: {'data': []});

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: MaterialApp(
        home: AdminListEntriesScreen(
          list: DailyList(
            id: 'l1',
            routeId: 'r1',
            routeName: 'Rota Universitária de Formiga',
            date: '2026-10-14',
            status: 'OPEN',
            totalEntries: 1,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a direção da viagem aparece para o admin', (tester) async {
    await abrirInscritos(tester);

    expect(find.byType(TripTypeChip), findsOneWidget);
    expect(find.text('Fernanda Costa'), findsOneWidget);
  });

  testWidgets('tocar na direção não abre o perfil do aluno', (tester) async {
    await abrirInscritos(tester);

    await tester.tap(find.byKey(const Key('entry_trip_type_$_userId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StudentProfileSheet), findsNothing);
  });

  testWidgets('tocar no nome ainda abre o perfil', (tester) async {
    await abrirInscritos(tester);

    await tester.tap(find.text('Fernanda Costa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StudentProfileSheet), findsOneWidget);
  });
}
