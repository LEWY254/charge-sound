import 'dart:math';

import 'package:flutter/material.dart';

enum _DragTarget { none, trimStart, trimEnd, playhead }

/// Scrollable waveform with trim handles, playhead scrub, and pinch-zoom.
class InteractiveWaveform extends StatefulWidget {
  final List<double> amplitudes;
  final Duration totalDuration;
  final Duration position;
  final Duration trimStart;
  final Duration trimEnd;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onTrimStartChanged;
  final ValueChanged<Duration> onTrimEndChanged;
  final bool enabled;

  const InteractiveWaveform({
    super.key,
    required this.amplitudes,
    required this.totalDuration,
    required this.position,
    required this.trimStart,
    required this.trimEnd,
    required this.onSeek,
    required this.onTrimStartChanged,
    required this.onTrimEndChanged,
    this.enabled = true,
  });

  @override
  State<InteractiveWaveform> createState() => _InteractiveWaveformState();
}

class _InteractiveWaveformState extends State<InteractiveWaveform> {
  final ScrollController _scroll = ScrollController();
  double _scale = 1.0;
  double _scaleStart = 1.0;
  _DragTarget _drag = _DragTarget.none;

  static const _barW = 3.0;
  static const _gap = 2.0;
  static const _hitSlop = 28.0;

  double get _unit => (_barW + _gap) * _scale;

  double _contentWidth(int n) => max(1.0, n * _unit);

  Duration _fromDx(double contentX) {
    final td = widget.totalDuration;
    if (td.inMicroseconds <= 0) return Duration.zero;
    final w = _contentWidth(widget.amplitudes.length);
    final t = (contentX / w).clamp(0.0, 1.0);
    return Duration(
      microseconds: (t * td.inMicroseconds).round(),
    );
  }

  double _toDx(Duration t) {
    final td = widget.totalDuration;
    if (td.inMicroseconds <= 0) return 0;
    final w = _contentWidth(widget.amplitudes.length);
    return (t.inMicroseconds / td.inMicroseconds) * w;
  }

  Duration _snap(Duration d) {
    final n = widget.amplitudes.length;
    if (n <= 0) return d;
    final td = widget.totalDuration;
    if (td.inMicroseconds <= 0) return d;
    final idx = ((d.inMicroseconds / td.inMicroseconds) * n).floor().clamp(0, n - 1);
    return Duration(
      microseconds: ((idx / n) * td.inMicroseconds).round(),
    );
  }

  _DragTarget _hitTest(double contentX) {
    final px = _toDx(widget.position);
    final sx = _toDx(widget.trimStart);
    final ex = _toDx(widget.trimEnd);
    if ((contentX - sx).abs() <= _hitSlop) return _DragTarget.trimStart;
    if ((contentX - ex).abs() <= _hitSlop) return _DragTarget.trimEnd;
    if ((contentX - px).abs() <= _hitSlop) return _DragTarget.playhead;
    return _DragTarget.none;
  }

  void _onPointerDown(PointerDownEvent e, double viewportW) {
    if (!widget.enabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(e.position);
    final contentX = (local.dx + _scroll.offset).clamp(
      0.0,
      _contentWidth(widget.amplitudes.length),
    );
    _drag = _hitTest(contentX);
    if (_drag == _DragTarget.none) {
      widget.onSeek(_snap(_fromDx(contentX)));
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!widget.enabled || _drag == _DragTarget.none) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(e.position);
    final contentX = (local.dx + _scroll.offset).clamp(
      0.0,
      _contentWidth(widget.amplitudes.length),
    );
    final t = _snap(_fromDx(contentX));
    final minGap = const Duration(milliseconds: 120);
    switch (_drag) {
      case _DragTarget.trimStart:
        final end = widget.trimEnd;
        final maxStart = end - minGap;
        widget.onTrimStartChanged(t > maxStart ? maxStart : t);
      case _DragTarget.trimEnd:
        final start = widget.trimStart;
        final minEnd = start + minGap;
        widget.onTrimEndChanged(t < minEnd ? minEnd : t);
      case _DragTarget.playhead:
        widget.onSeek(t);
      case _DragTarget.none:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _drag = _DragTarget.none;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amps = widget.amplitudes;
    final h = 132.0;
    final cw = _contentWidth(amps.length);

    return GestureDetector(
      onScaleStart: widget.enabled
          ? (d) => _scaleStart = _scale
          : null,
      onScaleUpdate: widget.enabled
          ? (d) {
              setState(() {
                _scale = (_scaleStart * d.scale).clamp(0.55, 3.2);
              });
            }
          : null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) =>
            _onPointerDown(e, MediaQuery.sizeOf(context).width),
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: (_) => _drag = _DragTarget.none,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: cs.surfaceContainerHighest,
            height: h,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: widget.enabled
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: max(cw, MediaQuery.sizeOf(context).width - 32),
                height: h,
                child: CustomPaint(
                  painter: _InteractiveWaveformPainter(
                    amplitudes: amps,
                    color: cs.primary,
                    dimColor: cs.primary.withValues(alpha: 0.22),
                    trimStart: widget.trimStart,
                    trimEnd: widget.trimEnd,
                    position: widget.position,
                    totalDuration: widget.totalDuration,
                    barUnit: _unit,
                  ),
                  size: Size(max(cw, MediaQuery.sizeOf(context).width - 32), h),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final Color dimColor;
  final Duration trimStart;
  final Duration trimEnd;
  final Duration position;
  final Duration totalDuration;
  final double barUnit;

  _InteractiveWaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.dimColor,
    required this.trimStart,
    required this.trimEnd,
    required this.position,
    required this.totalDuration,
    required this.barUnit,
  });

  double _xFor(Duration t, double width) {
    if (totalDuration.inMicroseconds <= 0) return 0;
    return (t.inMicroseconds / totalDuration.inMicroseconds) * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    final barW = barUnit * (3 / 5);
    final n = amplitudes.length;
    final totalW = n * barUnit;

    final trimSx = _xFor(trimStart, totalW);
    final trimEx = _xFor(trimEnd, totalW);
    final playX = _xFor(position, totalW);

    for (var i = 0; i < n; i++) {
      final x = i * barUnit;
      final cx = x + barW / 2;
      final amp = amplitudes[i].clamp(0.05, 1.0);
      final barHeight = amp * (size.height * 0.72);
      final y = (size.height - barHeight) / 2;

      final inSelection = cx >= trimSx && cx <= trimEx;
      final opacity = _edgeFade(i, n);

      final paint = Paint()
        ..color = (inSelection ? color : dimColor).withValues(alpha: opacity)
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(cx, y),
        Offset(cx, y + barHeight),
        paint,
      );
    }

    void drawVline(double x, Color c) {
      final p = Paint()
        ..color = c
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), p);
    }

    drawVline(trimSx, color.withValues(alpha: 0.85));
    drawVline(trimEx, color.withValues(alpha: 0.85));
    drawVline(playX, Colors.white);

    void handle(double x) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, size.height - 14), width: 10, height: 18),
        const Radius.circular(5),
      );
      canvas.drawRRect(r, Paint()..color = color);
    }

    handle(trimSx);
    handle(trimEx);
    canvas.drawCircle(Offset(playX, 10), 7, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(playX, 10), 5, Paint()..color = color);
  }

  double _edgeFade(int index, int total) {
    const fadeZone = 8;
    if (index < fadeZone) return 0.35 + (index / fadeZone) * 0.65;
    if (index > total - fadeZone) {
      return 0.35 + ((total - index) / fadeZone) * 0.65;
    }
    return 1.0;
  }

  @override
  bool shouldRepaint(covariant _InteractiveWaveformPainter oldDelegate) =>
      amplitudes != oldDelegate.amplitudes ||
      trimStart != oldDelegate.trimStart ||
      trimEnd != oldDelegate.trimEnd ||
      position != oldDelegate.position ||
      totalDuration != oldDelegate.totalDuration ||
      barUnit != oldDelegate.barUnit;
}
