import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/sound_event.dart';
import '../models/sound_item.dart';

class EventCard extends StatefulWidget {
  final SoundEventType eventType;
  final SoundItem? assignedSound;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;

  const EventCard({
    super.key,
    required this.eventType,
    this.assignedSound,
    required this.onTap,
    this.onPlayTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isConfigured = widget.assignedSound != null;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            _scaleController.forward().then((_) => _scaleController.reverse());
            widget.onTap();
          },
          onTapDown: (_) => _scaleController.forward(),
          onTapCancel: () => _scaleController.reverse(),
          splashColor: cs.primary.withValues(alpha: 0.08),
          child: Stack(
            children: [
              if (isConfigured)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      widget.eventType.icon,
                      size: 24,
                      color: cs.tertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.eventType.label,
                      style: tt.titleMedium?.copyWith(color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isConfigured
                                ? widget.assignedSound!.name
                                : 'Not set',
                            style: tt.bodySmall?.copyWith(
                              color: isConfigured
                                  ? cs.onSurfaceVariant
                                  : cs.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isConfigured)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton.filledTonal(
                              onPressed: widget.onPlayTap,
                              icon: const Icon(LucideIcons.play, size: 14),
                              style: IconButton.styleFrom(
                                backgroundColor: cs.primaryContainer,
                                foregroundColor: cs.onPrimaryContainer,
                                padding: EdgeInsets.zero,
                              ),
                              tooltip: 'Play ${widget.assignedSound!.name}',
                            ),
                          )
                        else
                          Icon(
                            LucideIcons.plus,
                            size: 20,
                            color: cs.outline,
                            semanticLabel: 'Add sound',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
