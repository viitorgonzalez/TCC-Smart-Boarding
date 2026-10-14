import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartboarding_app/features/institutions/providers/institution_provider.dart';
import 'package:smartboarding_app/features/routes/widgets/route_institutions_card.dart';

import '../support/fake_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('com o provider no contexto, o card monta', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.always(body: {'data': []});

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: InstitutionProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: RouteInstitutionsCard(
              routeId: 'rota-1',
              admitsNoInstitution: false,
              onAdmitsNoInstitutionChanged: (_) async {},
            ),
          ),
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
      MaterialApp(
        home: Scaffold(
          body: RouteInstitutionsCard(
            routeId: 'rota-1',
            admitsNoInstitution: false,
            onAdmitsNoInstitutionChanged: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isA<ProviderNotFoundException>());
  });

  testWidgets('a chave de aluno sem instituicao explica o estado', (
    tester,
  ) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.always(body: {'data': []});
    bool? escolhido;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: InstitutionProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: RouteInstitutionsCard(
              routeId: 'rota-1',
              admitsNoInstitution: false,
              onAdmitsNoInstitutionChanged: (v) async => escolhido = v,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Só entra quem declarou uma das instituições acima.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('route_admits_no_institution')),
    );
    await tester.tap(find.byKey(const Key('route_admits_no_institution')));
    await tester.pump();

    expect(escolhido, isTrue);
  });

  testWidgets('a chave reflete o proprio toque', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.always(body: {'data': []});

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: InstitutionProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: RouteInstitutionsCard(
              routeId: 'rota-1',
              admitsNoInstitution: false,
              onAdmitsNoInstitutionChanged: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final chave = find.byKey(const Key('route_admits_no_institution'));
    await tester.ensureVisible(chave);
    await tester.tap(chave);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.widget<SwitchListTile>(chave).value, isTrue);
    expect(
      find.text(
        'Quem não declarou instituição no perfil também entra nesta rota.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('falha ao salvar devolve a chave', (tester) async {
    final http = await installFakeHttp(token: 'jwt-de-teste');
    http.always(body: {'data': []});

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: InstitutionProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: RouteInstitutionsCard(
              routeId: 'rota-1',
              admitsNoInstitution: false,
              onAdmitsNoInstitutionChanged: (_) async =>
                  throw Exception('deu ruim'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final chave = find.byKey(const Key('route_admits_no_institution'));
    await tester.ensureVisible(chave);
    await tester.tap(chave);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.widget<SwitchListTile>(chave).value, isFalse);
  });
}
