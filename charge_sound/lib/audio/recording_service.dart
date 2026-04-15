import 'dart:async';

import 'package:record/record.dart';

/// Thin wrapper around [AudioRecorder]: AAC/m4a to disk, normalized amplitude stream.
class RecordingService {
  RecordingService() {
    _ampSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((a) {
      if (!_normalized.isClosed) {
        _normalized.add(_normalizeDb(a.current));
      }
    });
  }

  final AudioRecorder _recorder = AudioRecorder();
  late final StreamSubscription<Amplitude> _ampSubscription;
  final StreamController<double> _normalized = StreamController<double>.broadcast();

  /// Normalized 0.0–1.0 for live waveform.
  Stream<double> get onAmplitudeNormalized => _normalized.stream;

  static double _normalizeDb(double db) {
    const floor = -55.0;
    if (db <= floor) return 0.04;
    if (db >= 0) return 1.0;
    return ((db - floor) / (-floor)).clamp(0.04, 1.0);
  }

  /// Starts recording to [outputPath] (e.g. `.m4a`). Requests mic permission if needed.
  Future<void> start(String outputPath) async {
    final ok = await _recorder.hasPermission();
    if (!ok) {
      throw StateError('Microphone permission not granted');
    }
    final supported = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    final encoder = supported ? AudioEncoder.aacLc : AudioEncoder.wav;
    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: outputPath,
    );
  }

  /// Stops recording and returns the output file path.
  Future<String?> stop() => _recorder.stop();

  /// Stops and discards the output file/blob.
  Future<void> cancel() => _recorder.cancel();

  Future<String> preferredFileExtension() async {
    final supported = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    return supported ? 'm4a' : 'wav';
  }

  Future<void> dispose() async {
    await _ampSubscription.cancel();
    await _normalized.close();
    await _recorder.dispose();
  }
}
