import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/sound_item.dart';
import 'audio_seek_bar.dart';

class SoundTile extends StatelessWidget {
  final SoundItem sound;
  final bool isPlaying;
  final bool isSelected;
  final double playbackProgress;
  final VoidCallback? onPlayTap;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;
  final bool showOverflowMenu;
  final List<PopupMenuEntry<String>>? menuItems;
  final void Function(String)? onMenuSelected;
  final Duration? playPosition;
  final Duration? playDuration;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onFavoriteToggle;
  final String? folderName;

  const SoundTile({
    super.key,
    required this.sound,
    this.isPlaying = false,
    this.isSelected = false,
    this.playbackProgress = 0.0,
    this.onPlayTap,
    this.onTap,
    this.onSelect,
    this.showOverflowMenu = true,
    this.menuItems,
    this.onMenuSelected,
    this.playPosition,
    this.playDuration,
    this.onSeek,
    this.onFavoriteToggle,
    this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final showSeek = isPlaying &&
        onSeek != null &&
        playDuration != null &&
        playDuration!.inMilliseconds > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap ?? onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton.filledTonal(
                    onPressed: onPlayTap,
                    icon: Icon(
                      isPlaying ? LucideIcons.pause : LucideIcons.play,
                      size: 16,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isPlaying
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      foregroundColor: isPlaying
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
                      padding: EdgeInsets.zero,
                    ),
                    tooltip: isPlaying
                        ? 'Pause ${sound.name}'
                        : 'Play ${sound.name}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound.name,
                        style: tt.titleSmall?.copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sound.category != null || sound.createdAt != null)
                        Text(
                          sound.category ?? _formatDate(sound.createdAt!),
                          style:
                              tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Text(
                  sound.durationLabel,
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (onFavoriteToggle != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      sound.isFavorite ? LucideIcons.star : LucideIcons.starOff,
                      size: 16,
                    ),
                    tooltip: sound.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                ],
                if (onSelect != null) ...[
                  const SizedBox(width: 8),
                  _SelectionIndicator(
                    isSelected: isSelected,
                    onTap: onSelect!,
                  ),
                ],
                if (showOverflowMenu && menuItems != null) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: onMenuSelected,
                    itemBuilder: (_) => menuItems!,
                    icon: Icon(
                      LucideIcons.moreVertical,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    tooltip: 'More options',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (sound.tags.isNotEmpty || sound.folderId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, 16, 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (sound.folderId != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(folderName ?? 'Folder'),
                  ),
                for (final tag in sound.tags.take(3))
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(tag),
                  ),
              ],
            ),
          ),
        if (showSeek)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: AudioSeekBar(
              position: playPosition ?? Duration.zero,
              duration: playDuration!,
              onSeek: onSeek!,
              color: cs.primary,
              trackColor: cs.surfaceContainerHighest,
            ),
          )
        else if (isPlaying)
          LinearProgressIndicator(
            value: playbackProgress.clamp(0.0, 1.0),
            minHeight: 2,
            color: cs.primary,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        Divider(
          height: 0.5,
          thickness: 0.5,
          indent: 64,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionIndicator({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
            width: 2,
          ),
          color: isSelected ? cs.primary : Colors.transparent,
        ),
        child: isSelected
            ? Icon(Icons.check, size: 16, color: cs.onPrimary)
            : null,
      ),
    );
  }
}
