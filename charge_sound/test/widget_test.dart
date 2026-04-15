import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sound_trigger/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SoundTriggerApp()),
    );
    expect(
      find.textContaining('Sound Trigger'),
      findsWidgets,
    );
  });
}
