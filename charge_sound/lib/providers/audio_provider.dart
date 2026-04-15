import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_player_provider.dart';

/// Which sound id is active (playing or paused with loaded source).
final currentlyPlayingProvider = Provider<String?>((ref) {
  final s = ref.watch(audioPlayerProvider);
  return s.currentSoundId;
});
