import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's signature backdrop: a soft gradient with two large, slowly
/// drifting color blobs. Every screen sits on this, which is what makes
/// [GlassCard]'s blur actually read as "glass" instead of flat gray.
class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground> {
  // Deliberately not an AnimationController ticking at display refresh rate:
  // every GlassCard behind this background re-samples it (via BackdropFilter)
  // on every frame it repaints, so a 60fps-ticking background forces a blur
  // recompute on every visible glass card 60 times a second, forever — the
  // main source of jank across the app. The blob drift is slow and subtle
  // enough that ~11fps reads as identical to the eye while cutting that
  // recompute cost by more than 5x.
  static const _tickInterval = Duration(milliseconds: 90);
  static const _loopDuration = Duration(seconds: 18);

  late final Timer _timer;
  final _stopwatch = Stopwatch()..start();
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tickInterval, (_) {
      if (!mounted) return;
      final fraction =
          (_stopwatch.elapsedMilliseconds % _loopDuration.inMilliseconds) /
              _loopDuration.inMilliseconds;
      setState(() => _t = fraction * 2 * math.pi);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final baseColors = isDark
        ? const [Color(0xFF0A1230), Color(0xFF1A2247), Color(0xFF231A3B)]
        : const [Color(0xFFEFF2FC), Color(0xFFE7ECFB), Color(0xFFFBF0DD)];

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: baseColors,
            ),
          ),
        ),
        _Blob(
          color: scheme.secondary,
          size: 320,
          dx: 0.78 + 0.05 * math.cos(_t),
          dy: 0.08 + 0.04 * math.sin(_t),
          opacity: isDark ? 0.28 : 0.35,
        ),
        _Blob(
          color: scheme.primary,
          size: 380,
          dx: 0.05 + 0.04 * math.sin(_t * 0.8),
          dy: 0.75 + 0.05 * math.cos(_t * 0.8),
          opacity: isDark ? 0.32 : 0.28,
        ),
        widget.child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.dx,
    required this.dy,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double dx;
  final double dy;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(dx * 2 - 1, dy * 2 - 1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
