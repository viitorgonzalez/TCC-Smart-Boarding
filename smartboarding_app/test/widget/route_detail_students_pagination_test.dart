import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/features/institutions/providers/institution_provider.dart';
import 'package:smartboarding_app/features/routes/models/route_model.dart';
import 'package:smartboarding_app/features/routes/providers/route_provider.dart';
import 'package:smartboarding_app/features/routes/screens/route_detail_screen.dart';
import 'package:smartboarding_app/features/routes/services/route_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('abre o detalhe de uma rota com alunos sem cair no erro genérico', (
    tester,
  ) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.on('GET', '/api/routes/rota-1/stops', body: {'data': []});
    http.on('GET', '/api/routes/rota-1/vehicles', body: {'data': []});
    http.on('GET', '/api/lists', body: {'data': []});
    http.on(
      'GET',
      '/api/users',
      body: {
        'data': {
          'content': [
            {
              'id': 'u1',
              'email': 'ana@student.com',
              'fullName': 'Ana Oliveira',
              'role': 'STUDENT',
            },
          ],
          'number': 0,
          'totalPages': 1,
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: InstitutionProvider()),
            ChangeNotifierProvider.value(value: RouteProvider(RouteService())),
          ],
          child: RouteDetailScreen(
            route: RouteModel(
              id: 'rota-1',
              name: 'Rota Universitária',
              isActive: true,
              createdAt: '2026-01-01T00:00:00',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Erro inesperado'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
