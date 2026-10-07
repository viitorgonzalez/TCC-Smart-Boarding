import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/features/institutions/providers/institution_provider.dart';
import 'package:smartboarding_app/features/routes/models/route_model.dart';
import 'package:smartboarding_app/features/routes/providers/route_provider.dart';
import 'package:smartboarding_app/features/routes/screens/route_detail_screen.dart';
import 'package:smartboarding_app/features/routes/screens/route_section_screen.dart';
import 'package:smartboarding_app/features/routes/screens/invite_codes_screen.dart';
import 'package:smartboarding_app/features/routes/services/route_service.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirDetalhe(WidgetTester tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.always(body: {'data': []});

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(
                          value: InstitutionProvider(),
                        ),
                        ChangeNotifierProvider.value(
                          value: RouteProvider(RouteService()),
                        ),
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
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> abrirSecao(WidgetTester tester, String chave) async {
    final linha = find.byKey(Key(chave));
    await tester.scrollUntilVisible(
      linha,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(linha);
    await tester.pumpAndSettle();
    await tester.tap(linha);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a secao de instituicoes abre sem estourar provider', (
    tester,
  ) async {
    await abrirDetalhe(tester);

    await abrirSecao(tester, 'section_institutions');

    expect(find.byType(RouteSectionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a secao de codigos abre sem estourar provider', (tester) async {
    await abrirDetalhe(tester);

    await abrirSecao(tester, 'section_codes');

    expect(find.byType(InviteCodesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
