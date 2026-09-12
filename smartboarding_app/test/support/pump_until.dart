import 'package:flutter_test/flutter_test.dart';

/// Bombeia frames até [condition] valer, e para assim que valer.
///
/// Espera por condição, não por duração chutada. Um `pumpAndSettle` sozinho não
/// serve aqui: as requisições do Dio (mesmo com adaptador falso) só andam com
/// tempo real, e parte da cadeia de `setState` só anda com o relógio falso do
/// `testWidgets` avançando — nenhum dos dois sozinho é suficiente, por isso o
/// laço intercala `runAsync` e `pump`. [describe] entra na mensagem de falha:
/// sem ela, estourar o teto vira um timeout mudo.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String describe,
  int maxAttempts = 300,
}) async {
  var attempts = 0;
  while (!condition() && attempts < maxAttempts) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 1));
    attempts++;
  }
  if (!condition()) {
    fail('$describe não aconteceu após $maxAttempts tentativas.');
  }
  // Mais um pump sem duração: garante que o último setState virou frame
  // construído antes da asserção.
  await tester.pump();
}
