import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sound_trigger/models/sound_item.dart';
import 'package:sound_trigger/providers/recordings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('add/remove/rename recording', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const item = SoundItem(
      id: 'r1',
      name: 'Rec1',
      path: '/tmp/r1.m4a',
      duration: Duration(seconds: 1),
      source: SoundSource.recording,
    );
    await container.read(recordingsProvider.notifier).add(item);
    expect(container.read(recordingsProvider).length, 1);

    await container.read(recordingsProvider.notifier).rename('r1', 'NewName');
    expect(container.read(recordingsProvider).first.name, 'NewName');

    await container.read(recordingsProvider.notifier).remove('r1');
    expect(container.read(recordingsProvider), isEmpty);
  });
}
