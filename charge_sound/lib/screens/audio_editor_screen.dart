import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../audio/audio_processor.dart';
import '../audio/waveform_from_asset.dart';
import '../models/sound_item.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/interactive_waveform.dart';

String _fmtTime(Duration d) {
  final ms = d.inMilliseconds;
  final s = (ms / 1000).floor();
  final m = s ~/ 60;
  final r = s % 60;
  return '$m:${r.toString().padLeft(2, '0')}';
}

class AudioEditorScreen extends ConsumerStatefulWidget {
  final SoundItem sound;
  final List<double>? waveformOverride;

  const AudioEditorScreen({
    super.key,
    required this.sound,
    this.waveformOverride,
  });

  @override
  ConsumerState<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends ConsumerState<AudioEditorScreen> {
  late Duration _trimStart;
  late Duration _trimEnd;
  late Duration _fadeIn;
  late Duration _fadeOut;
  bool _loop = false;
  bool _loaded = false;
  List<double>? _amps;
  late SoundItem _workingSound;

  @override
  void initState() {
    super.initState();
    _workingSound = widget.sound;
    _trimStart = widget.sound.trimStart ?? Duration.zero;
    _trimEnd = widget.sound.trimEnd ?? widget.sound.duration;
    _fadeIn = widget.sound.fadeIn;
    _fadeOut = widget.sound.fadeOut;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    final notifier = ref.read(audioPlayerProvider.notifier);
    final base = _workingSound.copyWith(clearTrim: true);
    await notifier.loadSound(base);
    if (!mounted) return;
    final d = ref.read(audioPlayerProvider).duration;
    if (d > Duration.zero) {
      setState(() {
        if (_trimEnd > d) _trimEnd = d;
        if (_trimStart > _trimEnd - const Duration(milliseconds: 120)) {
          _trimStart = Duration.zero;
        }
      });
    }
    if (widget.waveformOverride != null) {
      setState(() => _amps = widget.waveformOverride);
    } else {
      final w = await waveformForSound(base);
      if (mounted) setState(() => _amps = w);
    }
  }

  Duration get _total =>
      ref.watch(audioPlayerProvider).duration > Duration.zero
          ? ref.watch(audioPlayerProvider).duration
          : _workingSound.duration;

  /// When previewing a clip, [AudioPlayer] reports position relative to the clip.
  Duration _displayPosition(AudioPlayerViewState ap) {
    if (ap.currentSoundId != _workingSound.id) return Duration.zero;
    final full = _total;
    if (full.inMilliseconds <= 0) return ap.position;
    final clipped =
        ap.duration < full - const Duration(milliseconds: 40);
    if (clipped) return _trimStart + ap.position;
    return ap.position;
  }

  bool get _dirty {
    final oS = widget.sound.trimStart ?? Duration.zero;
    final oE = widget.sound.trimEnd ?? widget.sound.duration;
    return _trimStart != oS ||
        _trimEnd != oE ||
        _fadeIn != widget.sound.fadeIn ||
        _fadeOut != widget.sound.fadeOut ||
        _workingSound.path != widget.sound.path;
  }

  SoundItem _resultSound() {
    final full = _total;
    final atStart = _trimStart <= const Duration(milliseconds: 50);
    final atEnd = _trimEnd >= full - const Duration(milliseconds: 50);
    if (atStart && atEnd) {
      return _workingSound.copyWith(
        clearTrim: true,
        fadeIn: _fadeIn,
        fadeOut: _fadeOut,
      );
    }
    return _workingSound.copyWith(
      trimStart: _trimStart,
      trimEnd: _trimEnd,
      fadeIn: _fadeIn,
      fadeOut: _fadeOut,
    );
  }

  Future<void> _previewSelection() async {
    final n = ref.read(audioPlayerProvider.notifier);
    final base = _workingSound.copyWith(clearTrim: true);
    await n.setSourceWithClip(base, _trimStart, _trimEnd);
    await n.seek(Duration.zero);
    await n.setLoopMode(_loop ? LoopMode.one : LoopMode.off);
    await n.resume();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ap = ref.watch(audioPlayerProvider);
    final pos = _displayPosition(ap);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _workingSound.name,
          style: tt.titleMedium?.copyWith(color: cs.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: _dirty
                ? () => Navigator.of(context).pop(_resultSound())
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(_workingSound.sourceLabel),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text('Full ${_fmtTime(_total)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text('Clip ${_fmtTime(_trimEnd - _trimStart)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_amps == null)
                const SizedBox(
                  height: 132,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                InteractiveWaveform(
                  amplitudes: _amps!,
                  totalDuration: _total,
                  position: pos,
                  trimStart: _trimStart,
                  trimEnd: _trimEnd,
                  onSeek: (t) async {
                    await ref.read(audioPlayerProvider.notifier).seek(t);
                  },
                  onTrimStartChanged: (t) => setState(() {
                    _trimStart = _clampDuration(
                      t,
                      Duration.zero,
                      _trimEnd - const Duration(milliseconds: 120),
                    );
                  }),
                  onTrimEndChanged: (t) => setState(() {
                    _trimEnd = _clampDuration(
                      t,
                      _trimStart + const Duration(milliseconds: 120),
                      _total,
                    );
                  }),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_fmtTime(_trimStart),
                      style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text(
                    _fmtTime(pos),
                    style: tt.titleSmall?.copyWith(color: cs.primary),
                  ),
                  const Spacer(),
                  Text(_fmtTime(_trimEnd),
                      style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Jump to trim start',
                    onPressed: () =>
                        ref.read(audioPlayerProvider.notifier).seek(_trimStart),
                    icon: const Icon(LucideIcons.skipBack, size: 20),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    onPressed: () async {
                      final n = ref.read(audioPlayerProvider.notifier);
                      if (ap.isPlaying) {
                        await n.pause();
                      } else {
                        // Restore full file if we were previewing a clip.
                        await n.loadSound(_workingSound.copyWith(clearTrim: true));
                        await n.resume();
                      }
                    },
                    child: Icon(
                      ap.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Jump to trim end',
                    onPressed: () =>
                        ref.read(audioPlayerProvider.notifier).seek(_trimEnd),
                    icon: const Icon(LucideIcons.skipForward, size: 20),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Loop selection preview',
                    isSelected: _loop,
                    onPressed: () => setState(() => _loop = !_loop),
                    icon: Icon(
                      LucideIcons.repeat,
                      color: _loop ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Fade in: ${_fmtTime(_fadeIn)}',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              Slider(
                value: _fadeIn.inMilliseconds.toDouble(),
                min: 0,
                max: (_trimEnd - _trimStart).inMilliseconds.clamp(500, 120000).toDouble(),
                onChanged: (v) {
                  setState(() {
                    _fadeIn = Duration(milliseconds: v.round());
                  });
                },
              ),
              Text('Fade out: ${_fmtTime(_fadeOut)}',
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              Slider(
                value: _fadeOut.inMilliseconds.toDouble(),
                min: 0,
                max: (_trimEnd - _trimStart).inMilliseconds.clamp(500, 120000).toDouble(),
                onChanged: (v) {
                  setState(() {
                    _fadeOut = Duration(milliseconds: v.round());
                  });
                },
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  const processor = AudioProcessor();
                  final parent = p.dirname(_workingSound.path);
                  final filename = p.basenameWithoutExtension(_workingSound.path);
                  final ext = p.extension(_workingSound.path);
                  final normalizedPath = '$parent/${filename}_normalized$ext';
                  final output = await processor.normalizeVolume(
                    _workingSound.path,
                    normalizedPath,
                  );
                  if (output == null || !mounted) return;
                  await ref
                      .read(audioPlayerProvider.notifier)
                      .loadSound(_workingSound.copyWith(path: output));
                  setState(() {
                    _workingSound = _workingSound.copyWith(path: output);
                    final d = ref.read(audioPlayerProvider).duration;
                    if (d > Duration.zero) {
                      _trimEnd = d;
                    }
                  });
                },
                icon: const Icon(LucideIcons.gauge, size: 18),
                label: const Text('Normalize'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _previewSelection,
                icon: const Icon(LucideIcons.headphones, size: 18),
                label: const Text('Preview selection'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _dirty
                    ? () => Navigator.of(context).pop(_resultSound())
                    : null,
                child: const Text('Apply trim'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

Duration _clampDuration(Duration v, Duration min, Duration max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}
