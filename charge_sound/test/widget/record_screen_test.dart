import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_trigger/screens/record_screen.dart';

void main() {
  testWidgets(
    'record screen renders title',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: RecordScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Record a Sound'), findsOneWidget);
    },
    skip: true,
  );
}
