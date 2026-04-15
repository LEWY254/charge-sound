import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final Color playedColor;
  final double playbackProgress;
  final bool isIdle;
  final Color idleColor;

  WaveformPainter({
    required this.amplitudes,
    required this.color,
    this.playedColor = Colors.transparent,
    this.playbackProgress = 0.0,
    this.isIdle = false,
    required this.idleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isIdle || amplitudes.isEmpty) {
      final paint = Paint()
        ..color = idleColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    const barWidth = 3.0;
    const barGap = 2.0;
    final totalBarWidth = barWidth + barGap;
    final barCount = (size.width / totalBarWidth).floor();
    final startIndex = max(0, amplitudes.length - barCount);
    final visibleAmps = amplitudes.sublist(startIndex);

    final playedIndex = (playbackProgress * visibleAmps.length).floor();

    for (var i = 0; i < visibleAmps.length; i++) {
      final amp = visibleAmps[i].clamp(0.05, 1.0);
      final barHeight = amp * (size.height * 0.8);
      final x = i * totalBarWidth;
      final y = (size.height - barHeight) / 2;

      final isPlayed = playedColor != Colors.transparent && i <= playedIndex;
      final opacity = _edgeFade(i, visibleAmps.length);

      final paint = Paint()
        ..color = (isPlayed ? playedColor : color).withValues(alpha: opacity)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barWidth / 2, y),
        Offset(x + barWidth / 2, y + barHeight),
        paint,
      );
    }
  }

  double _edgeFade(int index, int total) {
    const fadeZone = 8;
    if (index < fadeZone) return 0.3 + (index / fadeZone) * 0.7;
    if (index > total - fadeZone) {
      return 0.3 + ((total - index) / fadeZone) * 0.7;
    }
    return 1.0;
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      amplitudes != oldDelegate.amplitudes ||
      playbackProgress != oldDelegate.playbackProgress ||
      isIdle != oldDelegate.isIdle;
}
