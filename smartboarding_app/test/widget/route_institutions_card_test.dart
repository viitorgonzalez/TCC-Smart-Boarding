import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/features/institutions/providers/institution_provider.dart';
import 'package:smartboarding_app/features/routes/widgets/route_institutions_card.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// O card foi refatorado de props pra provider do contexto, mas a tela que o
  /// hospeda e empurrada num MaterialPageRoute -- que nasce no Navigator, acima
  /// dos providers de quem empurrou. Sem repassar, a secao "Instituicoes
  /// atendidas" estourava ProviderNotFoundException na cara do admin.
  testWidgets('com o provider no contexto, o card monta', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.always(body: {'data': []});

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: InstitutionProvider(),
        child: const MaterialApp(
          home: Scaffold(body: RouteInstitutionsCard(routeId: 'rota-1')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
  });

  testWidgets('sem o provider, falha -- e por isso ele e repassado', (
    tester,
  ) async {
    await installFakeHttp(token: 'jwt-de-teste');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RouteInstitutionsCard(routeId: 'rota-1')),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isA<ProviderNotFoundException>());
  });
}
