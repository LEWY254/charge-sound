import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sound_trigger/models/sound_event.dart';
import 'package:sound_trigger/models/sound_item.dart';
import 'package:sound_trigger/providers/event_config_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('assign/remove event sounds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const sound = SoundItem(
      id: 'x',
      name: 'X',
      path: '/tmp/x.mp3',
      duration: Duration(seconds: 1),
      source: SoundSource.file,
    );

    await container
        .read(eventConfigProvider.notifier)
        .assignSound(SoundEventType.alarm, sound);
    expect(container.read(eventConfigProvider)[SoundEventType.alarm]?.id, 'x');

    await container
        .read(eventConfigProvider.notifier)
        .removeSound(SoundEventType.alarm);
    expect(container.read(eventConfigProvider)[SoundEventType.alarm], isNull);
  });
}
