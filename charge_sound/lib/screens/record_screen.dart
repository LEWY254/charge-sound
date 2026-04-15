import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio/audio_processor.dart';
import '../audio/recording_service.dart';
import '../models/sound_item.dart';
import '../providers/audio_player_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/recordings_provider.dart';
import '../providers/sound_trim_store_provider.dart';
import '../utils/app_audio_dirs.dart';
import '../utils/audio_duration_probe.dart';
import '../widgets/waveform_painter.dart';
import 'audio_editor_screen.dart';

enum _RecordState { idle, recording, review }

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with TickerProviderStateMixin {
  _RecordState _state = _RecordState.idle;
  final List<double> _amplitudes = [];
  int _recordedSeconds = 0;
  Timer? _timer;
  StreamSubscription<double>? _ampSub;
  final _nameController = TextEditingController(text: 'My recording');
  DateTime? _recordStart;

  late final RecordingService _recording;
  String? _activeRecordPath;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _fabScaleController;
  late final Animation<double> _fabScaleAnimation;

  SoundItem? _recordingPreview;

  static const _maxSeconds = 30;
  static const _maxAmpSamples = 320;

  @override
  void initState() {
    super.initState();
    _recording = RecordingService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fabScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabScaleController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    if (_state == _RecordState.recording) {
      unawaited(_recording.cancel());
    }
    _timer?.cancel();
    unawaited(_ampSub?.cancel());
    unawaited(_recording.dispose());
    _pulseController.dispose();
    _fabScaleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _state = _RecordState.recording;
      _amplitudes.clear();
      _recordedSeconds = 0;
    });
    _pulseController.repeat(reverse: true);
    _fabScaleController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
    );

    final dir = await ensureRecordingsDirectory();
    final ext = await _recording.preferredFileExtension();
    final path =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.$ext';
    _activeRecordPath = path;
    _recordStart = DateTime.now();

    await _ampSub?.cancel();
    _ampSub = _recording.onAmplitudeNormalized.listen((v) {
      if (!mounted) return;
      setState(() {
        _amplitudes.add(v);
        if (_amplitudes.length > _maxAmpSamples) {
          _amplitudes.removeAt(0);
        }
      });
    });

    try {
      await _recording.start(path);
    } catch (e) {
      await _ampSub?.cancel();
      if (!mounted) return;
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _state = _RecordState.idle;
        _amplitudes.clear();
        _recordedSeconds = 0;
        _activeRecordPath = null;
        _recordStart = null;
      });
      final message = 'Could not start recording: $e';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _recordedSeconds++);
      if (_recordedSeconds >= _maxSeconds) {
        unawaited(_stopRecording());
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    await _ampSub?.cancel();
    _ampSub = null;
    _pulseController.stop();
    _pulseController.reset();

    final started = _recordStart ?? DateTime.now();
    var elapsed = DateTime.now().difference(started);
    if (elapsed > const Duration(seconds: _maxSeconds)) {
      elapsed = const Duration(seconds: _maxSeconds);
    }

    String? path;
    try {
      path = await _recording.stop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not stop recording: $e')),
        );
      }
      if (!mounted) return;
      setState(() {
        _state = _RecordState.idle;
        _amplitudes.clear();
        _recordedSeconds = 0;
        _activeRecordPath = null;
        _recordStart = null;
      });
      return;
    }

    path ??= _activeRecordPath;
    _activeRecordPath = null;
    _recordStart = null;

    if (path == null || !File(path).existsSync()) {
      if (!mounted) return;
      setState(() {
        _state = _RecordState.idle;
        _amplitudes.clear();
        _recordedSeconds = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording file was not created.')),
      );
      return;
    }

    var duration = elapsed;
    final probed = await probeAudioFileDuration(path);
    if (probed > Duration.zero) {
      duration = probed;
    }

    final name = _nameController.text.trim().isEmpty
        ? 'My recording'
        : _nameController.text.trim();
    final item = SoundItem(
      id: 'recording_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      path: path,
      duration: duration,
      source: SoundSource.recording,
      createdAt: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _recordingPreview = item;
      _state = _RecordState.review;
      _recordedSeconds = duration.inSeconds;
    });
  }

  Future<void> _reRecord() async {
    final prev = _recordingPreview;
    if (prev != null) {
      final ap = ref.read(audioPlayerProvider);
      if (ap.currentSoundId == prev.id) {
        ref.read(audioPlayerProvider.notifier).stop();
      }
      try {
        final f = File(prev.path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    setState(() {
      _state = _RecordState.idle;
      _amplitudes.clear();
      _recordedSeconds = 0;
      _recordingPreview = null;
    });
  }

  void _togglePreview() {
    final s = _recordingPreview;
    if (s == null) return;
    ref.read(audioPlayerProvider.notifier).togglePlay(s);
  }

  Future<void> _openTrimEditor() async {
    final s = _recordingPreview;
    if (s == null) return;
    final updated = await Navigator.of(context).push<SoundItem>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AudioEditorScreen(
          sound: s,
          waveformOverride: List<double>.from(_amplitudes),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _recordingPreview = updated);
    await ref.read(soundTrimStoreProvider.notifier).put(updated);
  }

  Future<void> _save() async {
    var s = _recordingPreview;
    if (s != null) {
      const processor = AudioProcessor();
      final ext = s.path.contains('.') ? s.path.substring(s.path.lastIndexOf('.')) : '.m4a';
      final normalizedPath =
          '${s.path.replaceFirst(ext, '')}_normalized$ext';
      final normalized = await processor.normalizeVolume(
        s.path,
        normalizedPath,
      );
      if (normalized != null) {
        final duration = await probeAudioFileDuration(normalized);
        final trim = await processor.autoDetectSilence(
          normalized,
          fallbackDurationMs: duration.inMilliseconds,
        );
        s = s.copyWith(
          path: normalized,
          duration: duration,
          trimStart: trim == null
              ? s.trimStart
              : Duration(milliseconds: trim.trimStartMs),
          trimEnd: trim == null
              ? s.trimEnd
              : Duration(milliseconds: trim.trimEndMs),
        );
      }
      ref.read(audioPlayerProvider.notifier).stop();
      await ref.read(recordingsProvider.notifier).add(s);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recording saved!'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            ref.read(selectedTabProvider.notifier).state = 1;
            ref.read(soundLibraryTabProvider.notifier).state = 2;
          },
        ),
      ),
    );
    setState(() {
      _state = _RecordState.idle;
      _amplitudes.clear();
      _recordedSeconds = 0;
      _recordingPreview = null;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final permissions = ref.watch(permissionProvider);
    final micDenied = permissions.maybeWhen(
      data: (m) => m[AppPermission.microphone] != PermissionStatus.granted,
      orElse: () => false,
    );
    final micPermanent = permissions.maybeWhen(
      data: (m) =>
          m[AppPermission.microphone] == PermissionStatus.permanentlyDenied,
      orElse: () => false,
    );
    final ap = ref.watch(audioPlayerProvider);
    final preview = _recordingPreview;
    final reviewPlaying = preview != null &&
        ap.currentSoundId == preview.id &&
        ap.isPlaying;
    final reviewProgress = preview != null &&
            ap.currentSoundId == preview.id &&
            ap.duration.inMilliseconds > 0
        ? ap.position.inMilliseconds / ap.duration.inMilliseconds
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Record a Sound',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (micDenied)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.micOff,
                                  size: 22,
                                  color: cs.onSecondaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    micPermanent
                                        ? 'Microphone is blocked. Open system settings to allow recording.'
                                        : 'Allow microphone access to record custom sounds.',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (micPermanent) {
                                      ref
                                          .read(permissionProvider.notifier)
                                          .openSettingsFor(
                                            AppPermission.microphone,
                                          );
                                    } else {
                                      ref
                                          .read(permissionProvider.notifier)
                                          .request(AppPermission.microphone);
                                    }
                                  },
                                  child:
                                      Text(micPermanent ? 'Settings' : 'Allow'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_state == _RecordState.idle)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Tap the mic to start.',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    Semantics(
                      excludeSemantics: true,
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: WaveformPainter(
                            amplitudes: _amplitudes,
                            color: cs.primary,
                            playedColor: _state == _RecordState.review
                                ? cs.primary
                                : Colors.transparent,
                            playbackProgress: reviewProgress,
                            isIdle: _state == _RecordState.idle,
                            idleColor: cs.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_state == _RecordState.recording)
                      Text(
                        '${_formatTime(_recordedSeconds)} / ${_formatTime(_maxSeconds)}',
                        style:
                            tt.headlineSmall?.copyWith(color: cs.onSurface),
                      ),
                    if (_state == _RecordState.review && preview != null)
                      Text(
                        preview.durationLabel,
                        style:
                            tt.headlineSmall?.copyWith(color: cs.onSurface),
                      ),
                    if (_state == _RecordState.idle)
                      const SizedBox(height: 24),
                    if (_state == _RecordState.idle ||
                        _state == _RecordState.recording)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: _buildFab(cs, micDenied),
                      ),
                    if (_state == _RecordState.review)
                      _buildReviewControls(
                        cs,
                        tt,
                        preview,
                        reviewPlaying,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFab(ColorScheme cs, bool micDenied) {
    final isRecording = _state == _RecordState.recording;

    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isRecording)
            ListenableBuilder(
              listenable: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.error.withValues(alpha: _pulseAnimation.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton.large(
              heroTag: 'record_fab',
              onPressed: micDenied && !isRecording
                  ? null
                  : isRecording
                      ? () {
                          unawaited(_stopRecording());
                        }
                      : _startRecording,
              backgroundColor: isRecording ? cs.error : cs.primaryContainer,
              foregroundColor: isRecording ? cs.onError : cs.onPrimaryContainer,
              shape: const CircleBorder(),
              child: Semantics(
                label: isRecording ? 'Stop recording' : 'Start recording',
                child: Icon(
                  isRecording ? LucideIcons.square : LucideIcons.mic,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewControls(
    ColorScheme cs,
    TextTheme tt,
    SoundItem? preview,
    bool reviewPlaying,
  ) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: preview == null ? null : _togglePreview,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    reviewPlaying ? LucideIcons.pause : LucideIcons.play,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(reviewPlaying ? 'Pause' : 'Play'),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: preview == null ? null : _openTrimEditor,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.scissors, size: 18),
                  SizedBox(width: 8),
                  Text('Trim'),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: _reRecord,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.rotateCcw, size: 18),
                  SizedBox(width: 8),
                  Text('Re-record'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Save as',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _save,
            child: const Text('Save Recording'),
          ),
        ),
      ],
    );
  }
}
