import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/sound_item.dart';

class AudioPlayerViewState {
  final String? currentSoundId;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isBuffering;

  const AudioPlayerViewState({
    this.currentSoundId,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isBuffering = false,
  });

  AudioPlayerViewState copyWith({
    String? currentSoundId,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    bool clearSound = false,
  }) {
    return AudioPlayerViewState(
      currentSoundId: clearSound ? null : (currentSoundId ?? this.currentSoundId),
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}

final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerViewState>(
  AudioPlayerNotifier.new,
);

class AudioPlayerNotifier extends Notifier<AudioPlayerViewState> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = [];

  AudioPlayer get _p {
    final player = _player;
    if (player == null) {
      throw StateError('AudioPlayer not initialized');
    }
    return player;
  }

  @override
  AudioPlayerViewState build() {
    _player = AudioPlayer();
    final player = _player!;

    void refreshFromPlayer() {
      state = state.copyWith(
        position: player.position,
        duration: player.duration ?? state.duration,
        isPlaying: player.playing,
        isBuffering: player.processingState == ProcessingState.buffering ||
            player.processingState == ProcessingState.loading,
      );
    }

    _subs.add(player.positionStream.listen((_) => refreshFromPlayer()));
    _subs.add(player.durationStream.listen((d) {
      state = state.copyWith(duration: d ?? Duration.zero);
    }));
    _subs.add(player.playerStateStream.listen((_) => refreshFromPlayer()));

    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _subs.clear();
      _player?.dispose();
      _player = null;
    });

    return const AudioPlayerViewState();
  }

  AudioSource _sourceFor(SoundItem sound) {
    final base = sound.path.startsWith('assets/')
        ? AudioSource.asset(sound.path)
        : AudioSource.file(sound.path);

    final start = sound.trimStart ?? Duration.zero;
    final end = sound.trimEnd;
    if (start > Duration.zero || end != null) {
      return ClippingAudioSource(
        child: base,
        start: start,
        end: end,
      );
    }
    return base;
  }

  /// Load source without playing (e.g. editor).
  Future<void> loadSound(SoundItem sound) async {
    await _p.stop();
    await _p.setAudioSource(_sourceFor(sound));
    state = state.copyWith(
      currentSoundId: sound.id,
      isPlaying: false,
      position: Duration.zero,
      clearSound: false,
    );
  }

  Future<void> playSound(SoundItem sound) async {
    final same = state.currentSoundId == sound.id;
    if (!same) {
      await _p.stop();
      await _p.setAudioSource(_sourceFor(sound));
      state = state.copyWith(
        currentSoundId: sound.id,
        isPlaying: false,
        position: Duration.zero,
      );
    }
    await _p.play();
  }

  Future<void> pause() => _p.pause();

  Future<void> resume() => _p.play();

  Future<void> stop() async {
    await _p.stop();
    state = state.copyWith(
      isPlaying: false,
      position: Duration.zero,
      clearSound: true,
    );
  }

  Future<void> seek(Duration position) => _p.seek(position);

  Future<void> setLoopMode(LoopMode mode) => _p.setLoopMode(mode);

  LoopMode get loopMode => _p.loopMode;

  Future<void> togglePlay(SoundItem sound) async {
    if (state.currentSoundId == sound.id && state.isPlaying) {
      await pause();
    } else if (state.currentSoundId == sound.id && !state.isPlaying) {
      await resume();
    } else {
      await playSound(sound);
    }
  }

  /// Replace audio source with explicit clip window (preview trim in editor).
  Future<void> setSourceWithClip(
    SoundItem sound,
    Duration clipStart,
    Duration? clipEnd,
  ) async {
    await _p.stop();
    final base = sound.path.startsWith('assets/')
        ? AudioSource.asset(sound.path)
        : AudioSource.file(sound.path);
    await _p.setAudioSource(
      ClippingAudioSource(
        child: base,
        start: clipStart,
        end: clipEnd,
      ),
    );
    state = state.copyWith(
      currentSoundId: sound.id,
      isPlaying: false,
      position: Duration.zero,
    );
  }
}
