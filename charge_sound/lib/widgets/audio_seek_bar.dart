import 'package:flutter/material.dart';

/// Thin seek bar: tap or horizontal drag to change [Duration].
class AudioSeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final Color color;
  final Color trackColor;

  const AudioSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.color,
    required this.trackColor,
  });

  void _seekFromDx(double dx, double width) {
    if (width <= 0 || duration.inMilliseconds <= 0) return;
    final t = (dx / width).clamp(0.0, 1.0);
    final ms = (t * duration.inMilliseconds).round();
    onSeek(Duration(milliseconds: ms));
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Semantics(
      label: 'Seek audio',
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _seekFromDx(d.localPosition.dx, w),
            onHorizontalDragUpdate: (d) =>
                _seekFromDx(d.localPosition.dx, w),
            child: SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: w,
                    height: 3,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: w * progress.clamp(0.0, 1.0),
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: (w * progress).clamp(0.0, w) - 6,
                    top: 3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
