import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_trigger/models/sound_item.dart';
import 'package:sound_trigger/screens/audio_editor_screen.dart';

void main() {
  testWidgets('audio editor renders controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    const sound = SoundItem(
      id: 'x',
      name: 'Clip',
      path: 'assets/meme_sounds/bruh.mp3',
      duration: Duration(seconds: 2),
      source: SoundSource.meme,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AudioEditorScreen(sound: sound)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Save'), findsOneWidget);
  });
}
