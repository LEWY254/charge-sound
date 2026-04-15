import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_trigger/screens/sound_library_screen.dart';

void main() {
  testWidgets('sound library renders tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SoundLibraryScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('My Files'), findsOneWidget);
    expect(find.text('Recordings'), findsOneWidget);
  });
}
