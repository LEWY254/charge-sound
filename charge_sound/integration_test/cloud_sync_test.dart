import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_trigger/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings shows account sync section', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2200));
    await tester.pumpWidget(const ProviderScope(child: SoundTriggerApp()));
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    if (find.text('Next').evaluate().isNotEmpty) {
      for (var i = 0; i < 3; i++) {
        if (find.text('Next').evaluate().isEmpty) break;
        await tester.tap(find.text('Next').first);
        await tester.pumpAndSettle();
      }
      if (find.text('Finish').evaluate().isNotEmpty) {
        await tester.tap(find.text('Finish').first);
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.textContaining('Sign in with Email'), findsWidgets);
    expect(find.textContaining('Sign in with Google'), findsWidgets);
  });
}
