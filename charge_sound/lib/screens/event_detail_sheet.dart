import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/meme_sounds.dart';
import '../models/sound_event.dart';
import '../models/sound_item.dart';
import '../providers/audio_player_provider.dart';
import '../providers/event_config_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/recordings_provider.dart';
import '../providers/sound_trim_store_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_files_provider.dart';
import '../platform/android_write_settings.dart';
import 'sound_library_screen.dart';
import '../widgets/audio_seek_bar.dart';
import '../widgets/sound_tile.dart';
import 'audio_editor_screen.dart';

enum _SourceTab { myFiles, memeSounds, recorded }

class EventDetailSheet extends ConsumerStatefulWidget {
  final SoundEventType eventType;

  const EventDetailSheet({super.key, required this.eventType});

  @override
  ConsumerState<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends ConsumerState<EventDetailSheet> {
  _SourceTab _selectedTab = _SourceTab.memeSounds;
  SoundItem? _selectedSound;

  @override
  void initState() {
    super.initState();
    final configs = ref.read(eventConfigProvider);
    _selectedSound = configs[widget.eventType];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final configs = ref.watch(eventConfigProvider);
    final currentSound = configs[widget.eventType];
    final ap = ref.watch(audioPlayerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(widget.eventType.icon, size: 28, color: cs.tertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventType.label,
                      style: tt.titleLarge?.copyWith(color: cs.onSurface),
                    ),
                    Text(
                      widget.eventType.description,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (currentSound != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CurrentSoundCard(
              sound: currentSound,
              isPlaying:
                  ap.currentSoundId == currentSound.id && ap.isPlaying,
              position: ap.currentSoundId == currentSound.id ? ap.position : null,
              duration: ap.currentSoundId == currentSound.id ? ap.duration : null,
              onPlay: () => _togglePlay(currentSound),
              onSeek: ap.currentSoundId == currentSound.id
                  ? (d) =>
                      ref.read(audioPlayerProvider.notifier).seek(d)
                  : null,
              onTrim: () => _editSound(currentSound),
              onRemove: () =>
                  ref.read(eventConfigProvider.notifier).removeSound(widget.eventType),
            ),
          ),
        if (currentSound != null) const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'CHOOSE A SOUND',
            style: tt.labelLarge?.copyWith(color: cs.primary),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<_SourceTab>(
            segments: const [
              ButtonSegment(value: _SourceTab.myFiles, label: Text('My Files')),
              ButtonSegment(
                  value: _SourceTab.memeSounds, label: Text('Meme Sounds')),
              ButtonSegment(
                  value: _SourceTab.recorded, label: Text('Recorded')),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              textStyle: tt.labelMedium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildSoundList(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            children: [
              if (widget.eventType.isSystemDefault)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _selectedSound != null
                          ? () => _onSetAsSystemDefault()
                          : null,
                      child: const Text('Set as System Default'),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedSound != null ? _applySound : null,
                  child: const Text('Apply Sound'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
      ],
    );
  }

  Widget _buildSoundList(BuildContext context) {
    final List<SoundItem> sounds;
    switch (_selectedTab) {
      case _SourceTab.myFiles:
        sounds = ref.watch(userFilesProvider);
      case _SourceTab.memeSounds:
        sounds = allMemeSounds;
      case _SourceTab.recorded:
        sounds = ref.watch(recordingsProvider);
    }

    if (sounds.isEmpty) {
      return _EmptyTab(
        tab: _selectedTab,
        onSwitchTab: (tab) => setState(() => _selectedTab = tab),
      );
    }

    final overrides = ref.watch(soundTrimStoreProvider);
    final ap = ref.watch(audioPlayerProvider);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        final resolved = overrides[sound.id] ?? sound;
        final isThis = ap.currentSoundId == resolved.id;
        return SoundTile(
          sound: resolved,
          isPlaying: isThis && ap.isPlaying,
          isSelected: _selectedSound?.id == resolved.id,
          onPlayTap: () => _togglePlay(resolved),
          onSelect: () => setState(() => _selectedSound = resolved),
          showOverflowMenu: false,
          playPosition: isThis ? ap.position : null,
          playDuration: isThis ? ap.duration : null,
          onSeek: isThis
              ? (d) => ref.read(audioPlayerProvider.notifier).seek(d)
              : null,
        );
      },
    );
  }

  void _togglePlay(SoundItem sound) {
    ref.read(audioPlayerProvider.notifier).togglePlay(sound);
  }

  Future<void> _editSound(SoundItem sound) async {
    final updated = await Navigator.of(context).push<SoundItem>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AudioEditorScreen(sound: sound),
      ),
    );
    if (!mounted || updated == null) return;
    await ref.read(soundTrimStoreProvider.notifier).put(updated);
    await ref
        .read(eventConfigProvider.notifier)
        .assignSound(widget.eventType, updated);
    setState(() => _selectedSound = updated);
  }

  Future<void> _applySound() async {
    if (_selectedSound == null) return;
    if (widget.eventType.isSystemDefault) {
      final allowed =
          await _ensureWriteSettingsPermissionForSystemSound();
      if (!allowed || !mounted) return;
      final applied = await _applySystemDefaultNow(_selectedSound!);
      if (!applied || !mounted) return;
    }
    ref
        .read(eventConfigProvider.notifier)
        .assignSound(widget.eventType, _selectedSound!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onSetAsSystemDefault() async {
    if (_selectedSound == null) return;
    final allowed = await _ensureWriteSettingsPermissionForSystemSound();
    if (!allowed || !mounted) return;
    await _applySystemDefaultNow(_selectedSound!);
  }

  Future<bool> _applySystemDefaultNow(SoundItem sound) async {
    final result = await AndroidWriteSettings.setSystemDefaultSound(
      eventType: widget.eventType.name,
      soundPath: sound.path,
      soundName: sound.name,
    );
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (!result.success) {
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Open system sound settings'),
          content: const Text(
            'Automatic assignment failed. You can still set it manually in '
            'Android system sound settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (shouldOpen == true && mounted) {
        await AndroidWriteSettings.openSystemSoundSettings();
      }
    }
    return result.success;
  }

  /// Returns true only if WRITE_SETTINGS is already granted. Otherwise shows a
  /// dialog and returns false (user may open settings and try again).
  Future<bool> _ensureWriteSettingsPermissionForSystemSound() async {
    final granted = await ref
        .read(permissionProvider.notifier)
        .isGranted(AppPermission.systemSettings);
    if (granted) return true;
    if (!mounted) return false;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modify system settings'),
        content: const Text(
          'To use this sound for your ringtone, notification, or alarm, '
          'Sound Trigger needs permission to modify system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (open == true && mounted) {
      await ref
          .read(permissionProvider.notifier)
          .openSettingsFor(AppPermission.systemSettings);
    }
    return false;
  }
}

class _CurrentSoundCard extends StatelessWidget {
  final SoundItem sound;
  final bool isPlaying;
  final Duration? position;
  final Duration? duration;
  final VoidCallback onPlay;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback onTrim;
  final VoidCallback onRemove;

  const _CurrentSoundCard({
    required this.sound,
    required this.isPlaying,
    this.position,
    this.duration,
    required this.onPlay,
    this.onSeek,
    required this.onTrim,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final showSeek = isPlaying &&
        onSeek != null &&
        duration != null &&
        duration!.inMilliseconds > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.music, size: 20, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.name,
                      style: tt.titleSmall?.copyWith(color: cs.onSurface),
                    ),
                    Text(
                      '${sound.durationLabel} - ${sound.sourceLabel}',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onTrim,
                icon: Icon(LucideIcons.scissors, size: 18, color: cs.tertiary),
                tooltip: 'Trim / edit',
              ),
              IconButton(
                onPressed: onPlay,
                icon: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play,
                    size: 18),
                tooltip: isPlaying ? 'Pause' : 'Play',
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(LucideIcons.x, size: 18, color: cs.error),
                tooltip: 'Remove sound',
              ),
            ],
          ),
          if (showSeek) ...[
            const SizedBox(height: 8),
            AudioSeekBar(
              position: position ?? Duration.zero,
              duration: duration!,
              onSeek: onSeek!,
              color: cs.primary,
              trackColor: cs.surfaceContainerLow,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyTab extends ConsumerWidget {
  final _SourceTab tab;
  final ValueChanged<_SourceTab> onSwitchTab;

  const _EmptyTab({
    required this.tab,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final (IconData icon, String message, String action) = switch (tab) {
      _SourceTab.myFiles => (
          LucideIcons.folderOpen,
          'No audio files added yet.',
          'Browse Files',
        ),
      _SourceTab.memeSounds => (
          LucideIcons.music,
          'No meme sounds available.',
          'Use My Files',
        ),
      _SourceTab.recorded => (
          LucideIcons.mic,
          'No recordings yet.\nRecord your first sound clip.',
          'Record Now',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action.isNotEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  switch (tab) {
                    case _SourceTab.myFiles:
                      pickAndAddUserFile(context, ref);
                    case _SourceTab.recorded:
                      Navigator.of(context).pop();
                      ref.read(selectedTabProvider.notifier).state = 3;
                    case _SourceTab.memeSounds:
                      onSwitchTab(_SourceTab.myFiles);
                  }
                },
                child: Text(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
