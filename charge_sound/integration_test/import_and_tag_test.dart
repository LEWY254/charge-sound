import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_trigger/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sound library search/filter controls available', (tester) async {
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

    await tester.tap(find.text('Sounds').first);
    await tester.pumpAndSettle();
    expect(find.text('Sound Library'), findsOneWidget);
    expect(find.textContaining('Tags'), findsWidgets);
    expect(find.textContaining('Folders'), findsWidgets);

    await tester.enterText(find.byType(SearchBar).first, 'bruh');
    await tester.pumpAndSettle();
    expect(find.textContaining('Bruh'), findsWidgets);
  });
}
