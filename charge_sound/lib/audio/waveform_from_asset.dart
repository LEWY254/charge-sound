import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/sound_item.dart';

/// Cheap waveform preview: sample absolute byte deltas from asset bytes.
/// Not a true audio envelope but reads fast and looks waveform-like.
Future<List<double>> waveformFromAssetBytes(
  String assetPath, {
  int barCount = 280,
}) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  if (bytes.isEmpty) return List.filled(barCount, 0.2);

  final chunk = max(1, bytes.length ~/ barCount);
  final amps = <double>[];
  for (var i = 0; i < barCount; i++) {
    final start = i * chunk;
    final end = min(start + chunk, bytes.length);
    var sum = 0;
    for (var j = start; j < end; j++) {
      sum += bytes[j].abs();
    }
    amps.add(sum / (end - start) / 255.0);
  }
  final maxA = amps.reduce(max);
  if (maxA <= 0) return List.filled(barCount, 0.2);
  return amps.map((a) => (a / maxA).clamp(0.05, 1.0)).toList();
}

Future<List<double>> waveformFromFileBytes(
  Uint8List bytes, {
  int barCount = 280,
}) async {
  if (bytes.isEmpty) return List.filled(barCount, 0.2);
  final chunk = max(1, bytes.length ~/ barCount);
  final amps = <double>[];
  for (var i = 0; i < barCount; i++) {
    final start = i * chunk;
    final end = min(start + chunk, bytes.length);
    var sum = 0;
    for (var j = start; j < end; j++) {
      sum += bytes[j].abs();
    }
    amps.add(sum / (end - start) / 255.0);
  }
  final maxA = amps.reduce(max);
  if (maxA <= 0) return List.filled(barCount, 0.2);
  return amps.map((a) => (a / maxA).clamp(0.05, 1.0)).toList();
}

Future<List<double>> waveformForSound(
  SoundItem sound, {
  int barCount = 280,
}) async {
  if (sound.path.startsWith('assets/')) {
    return waveformFromAssetBytes(sound.path, barCount: barCount);
  }
  try {
    final f = File(sound.path);
    if (!await f.exists()) return List.filled(barCount, 0.2);
    final bytes = await f.readAsBytes();
    return waveformFromFileBytes(bytes, barCount: barCount);
  } catch (_) {
    return List.filled(barCount, 0.2);
  }
}
