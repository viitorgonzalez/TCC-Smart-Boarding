import 'package:flutter_test/flutter_test.dart';

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
  await tester.pump();
}
