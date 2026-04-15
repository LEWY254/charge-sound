import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_trigger/app.dart';
import 'package:sound_trigger/widgets/event_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens event detail and sound chooser flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2200));
    await tester.pumpWidget(const ProviderScope(child: SoundTriggerApp()));
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    final next = find.text('Next');
    if (next.evaluate().isNotEmpty) {
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

    expect(find.byType(EventCard), findsWidgets);
    await tester.tap(find.byType(EventCard).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('CHOOSE A SOUND'), findsOneWidget);
    expect(find.text('Meme Sounds'), findsWidgets);
  });
}
