import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class AudioTrimSuggestion {
  const AudioTrimSuggestion({
    required this.trimStartMs,
    required this.trimEndMs,
  });

  final int trimStartMs;
  final int trimEndMs;
}

class AudioProcessor {
  const AudioProcessor();

  Future<AudioTrimSuggestion?> autoDetectSilence(
    String path, {
    int fallbackDurationMs = 30000,
  }) async {
    if (fallbackDurationMs <= 0) return null;
    final file = File(path);
    if (!await file.exists()) return null;

    final wav = await _tryReadPcm16Wav(path);
    if (wav == null) {
      // Without PCM samples we cannot reliably detect silence boundaries.
      // Return null so callers keep full clip unchanged.
      return null;
    }

    const silenceThreshold = 0.015; // ~ -36.5 dBFS
    const leadOutPaddingMs = 24;
    const leadInPaddingMs = 24;

    final totalFrames = wav.totalFrames;
    if (totalFrames <= 0) return null;

    int firstSoundFrame = 0;
    bool foundStart = false;
    for (var frame = 0; frame < totalFrames; frame++) {
      if (_framePeak(wav, frame) >= silenceThreshold) {
        firstSoundFrame = frame;
        foundStart = true;
        break;
      }
    }
    if (!foundStart) return null;

    int lastSoundFrame = totalFrames - 1;
    for (var frame = totalFrames - 1; frame >= 0; frame--) {
      if (_framePeak(wav, frame) >= silenceThreshold) {
        lastSoundFrame = frame;
        break;
      }
    }

    final startMs = ((firstSoundFrame * 1000) / wav.sampleRate).round();
    final endMsExclusive =
        (((lastSoundFrame + 1) * 1000) / wav.sampleRate).round();
    final durationMs = ((totalFrames * 1000) / wav.sampleRate).round();

    final trimStartMs = math.max(0, startMs - leadInPaddingMs);
    final trimEndMs = math.min(durationMs, endMsExclusive + leadOutPaddingMs);
    if (trimEndMs <= trimStartMs) return null;

    return AudioTrimSuggestion(
      trimStartMs: trimStartMs,
      trimEndMs: trimEndMs,
    );
  }

  Future<String?> normalizeVolume(
    String inputPath,
    String outputPath,
  ) async {
    final inFile = File(inputPath);
    if (!await inFile.exists()) return null;

    final wav = await _tryReadPcm16Wav(inputPath);
    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    if (await outFile.exists()) {
      await outFile.delete();
    }

    if (wav == null) {
      // Preserve behavior for non-PCM formats until platform codecs are added.
      await inFile.copy(outputPath);
      return outputPath;
    }

    var peak = 0;
    for (var frame = 0; frame < wav.totalFrames; frame++) {
      for (var ch = 0; ch < wav.channels; ch++) {
        final sample = _readSample(wav, frame, ch).abs();
        if (sample > peak) peak = sample;
      }
    }
    if (peak == 0) {
      await inFile.copy(outputPath);
      return outputPath;
    }

    const targetPeak = 29490.0; // ~ -1 dBFS
    var gain = targetPeak / peak.toDouble();
    if (gain > 8.0) gain = 8.0; // avoid aggressive noise amplification
    if (gain < 1.0) gain = 1.0; // don't attenuate here, keep intent simple

    if ((gain - 1.0).abs() < 0.01) {
      await inFile.copy(outputPath);
      return outputPath;
    }

    final normalized = Uint8List.fromList(wav.bytes);
    final outView = ByteData.sublistView(normalized);
    for (var frame = 0; frame < wav.totalFrames; frame++) {
      for (var ch = 0; ch < wav.channels; ch++) {
        final index = wav.dataOffset + ((frame * wav.channels + ch) * 2);
        final s = outView.getInt16(index, Endian.little);
        final scaled = (s * gain).round().clamp(-32768, 32767);
        outView.setInt16(index, scaled, Endian.little);
      }
    }

    await outFile.writeAsBytes(normalized, flush: true);
    return outputPath;
  }

  static int _readSample(_Pcm16Wav wav, int frame, int channel) {
    final index = wav.dataOffset + ((frame * wav.channels + channel) * 2);
    return wav.byteData.getInt16(index, Endian.little);
  }

  static double _framePeak(_Pcm16Wav wav, int frame) {
    var peak = 0;
    for (var ch = 0; ch < wav.channels; ch++) {
      final s = _readSample(wav, frame, ch).abs();
      if (s > peak) peak = s;
    }
    return peak / 32768.0;
  }

  static Future<_Pcm16Wav?> _tryReadPcm16Wav(String path) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.length < 44) return null;
    final bd = ByteData.sublistView(bytes);

    if (_fourCC(bytes, 0) != 'RIFF') return null;
    if (_fourCC(bytes, 8) != 'WAVE') return null;

    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataOffset;
    int? dataLength;
    var cursor = 12;

    while (cursor + 8 <= bytes.length) {
      final chunkId = _fourCC(bytes, cursor);
      final chunkSize = bd.getUint32(cursor + 4, Endian.little);
      final chunkDataOffset = cursor + 8;
      if (chunkDataOffset + chunkSize > bytes.length) break;

      if (chunkId == 'fmt ') {
        if (chunkSize < 16) return null;
        final format = bd.getUint16(chunkDataOffset, Endian.little);
        channels = bd.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = bd.getUint32(chunkDataOffset + 4, Endian.little);
        bitsPerSample = bd.getUint16(chunkDataOffset + 14, Endian.little);
        if (format != 1) return null; // PCM only
      } else if (chunkId == 'data') {
        dataOffset = chunkDataOffset;
        dataLength = chunkSize;
      }

      cursor = chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }

    if (channels == null ||
        sampleRate == null ||
        bitsPerSample == null ||
        dataOffset == null ||
        dataLength == null) {
      return null;
    }
    if (channels <= 0 || sampleRate <= 0 || bitsPerSample != 16) return null;
    if (dataLength < channels * 2) return null;

    return _Pcm16Wav(
      bytes: bytes,
      byteData: bd,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      dataOffset: dataOffset,
      dataLength: dataLength,
    );
  }

  static String _fourCC(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) return '';
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }
}

class _Pcm16Wav {
  const _Pcm16Wav({
    required this.bytes,
    required this.byteData,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataLength,
  });

  final Uint8List bytes;
  final ByteData byteData;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataOffset;
  final int dataLength;

  int get totalFrames => dataLength ~/ (channels * 2);
}
