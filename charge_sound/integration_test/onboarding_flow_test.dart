import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_trigger/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding flow reaches home shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2200));
    await tester.pumpWidget(
      const ProviderScope(
        child: SoundTriggerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Welcome to Sound Trigger'), findsWidgets);

    for (var i = 0; i < 3; i++) {
      final next = find.text('Next');
      if (next.evaluate().isEmpty) break;
      await tester.tap(next.first);
      await tester.pumpAndSettle();
    }

    final finish = find.text('Finish');
    if (finish.evaluate().isNotEmpty) {
      await tester.tap(finish.first);
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Customize every beep.'), findsOneWidget);
  });
}
