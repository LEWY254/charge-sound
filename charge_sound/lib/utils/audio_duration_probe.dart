import 'dart:async';

import 'package:just_audio/just_audio.dart';

Future<Duration> probeAudioFileDuration(String filePath) async {
  final player = AudioPlayer();
  try {
    await player.setAudioSource(AudioSource.file(filePath));
    Duration? d = player.duration;
    if (d != null && d > Duration.zero) return d;
    d = await player.durationStream
        .where((x) {
          final v = x;
          return v != null && v > Duration.zero;
        })
        .map((x) => x!)
        .first
        .timeout(const Duration(seconds: 3), onTimeout: () => Duration.zero);
    return d;
  } catch (_) {
    return Duration.zero;
  } finally {
    await player.dispose();
  }
}
