import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sound_trigger/audio/audio_processor.dart';

void main() {
  test('audio processor instantiates', () {
    const processor = AudioProcessor();
    expect(processor, isA<AudioProcessor>());
  });

  test('detects leading and trailing silence in pcm wav', () async {
    const processor = AudioProcessor();
    final tempDir = await Directory.systemTemp.createTemp('audio_proc_test_');
    final wavPath = '${tempDir.path}/silence_then_tone.wav';
    final wavFile = File(wavPath);

    // 1 second mono @ 16kHz:
    // 200ms silence, 600ms tone-ish, 200ms silence.
    final sampleRate = 16000;
    final samples = List<int>.filled(sampleRate, 0);
    for (var i = 3200; i < 12800; i++) {
      samples[i] = ((i.isEven ? 1 : -1) * 6000);
    }
    await wavFile.writeAsBytes(_buildPcm16Wav(samples, sampleRate: sampleRate));

    final trim = await processor.autoDetectSilence(
      wavPath,
      fallbackDurationMs: 1000,
    );
    expect(trim, isNotNull);
    expect(trim!.trimStartMs, inInclusiveRange(150, 230));
    expect(trim.trimEndMs, inInclusiveRange(760, 850));

    await tempDir.delete(recursive: true);
  });

  test('normalizes pcm wav peak level', () async {
    const processor = AudioProcessor();
    final tempDir = await Directory.systemTemp.createTemp('audio_norm_test_');
    final inputPath = '${tempDir.path}/quiet.wav';
    final outputPath = '${tempDir.path}/normalized.wav';

    final inputSamples = <int>[500, -500, 1200, -1200, 800, -800, 400, -400];
    await File(inputPath).writeAsBytes(_buildPcm16Wav(inputSamples));

    final out = await processor.normalizeVolume(inputPath, outputPath);
    expect(out, outputPath);

    final normalizedBytes = await File(outputPath).readAsBytes();
    final normalizedSamples = _readPcm16Samples(normalizedBytes);
    final peak = normalizedSamples
        .map((e) => e.abs())
        .fold<int>(0, (a, b) => a > b ? a : b);
    expect(peak, greaterThan(1200));

    await tempDir.delete(recursive: true);
  });
}

Uint8List _buildPcm16Wav(
  List<int> samples, {
  int sampleRate = 8000,
  int channels = 1,
}) {
  final dataSize = samples.length * 2;
  final totalSize = 44 + dataSize;
  final bytes = Uint8List(totalSize);
  final bd = ByteData.sublistView(bytes);

  _writeFourCC(bytes, 0, 'RIFF');
  bd.setUint32(4, 36 + dataSize, Endian.little);
  _writeFourCC(bytes, 8, 'WAVE');
  _writeFourCC(bytes, 12, 'fmt ');
  bd.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  bd.setUint16(20, 1, Endian.little); // PCM format
  bd.setUint16(22, channels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * channels * 2, Endian.little); // byte rate
  bd.setUint16(32, channels * 2, Endian.little); // block align
  bd.setUint16(34, 16, Endian.little); // bits per sample
  _writeFourCC(bytes, 36, 'data');
  bd.setUint32(40, dataSize, Endian.little);

  var offset = 44;
  for (final s in samples) {
    bd.setInt16(offset, s.clamp(-32768, 32767), Endian.little);
    offset += 2;
  }
  return bytes;
}

void _writeFourCC(Uint8List target, int offset, String value) {
  final codes = value.codeUnits;
  for (var i = 0; i < 4; i++) {
    target[offset + i] = codes[i];
  }
}

List<int> _readPcm16Samples(Uint8List wav) {
  final bd = ByteData.sublistView(wav);
  final out = <int>[];
  for (var offset = 44; offset + 1 < wav.length; offset += 2) {
    out.add(bd.getInt16(offset, Endian.little));
  }
  return out;
}
