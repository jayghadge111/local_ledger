import '../../../core/money_format.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/category_icons.dart';
import '../../../core/theme/app_theme.dart';

class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.iconKey,
    required this.amountMinor,
    required this.fraction,
  });

  final String label;
  final String? iconKey;
  final int amountMinor;
  final double fraction;
}

/// A ring chart of category spend, each segment shaded from black down to
/// light gray by rank — a strictly monochrome take on the usual multicolor
/// donut, so it still fits the "Uber Slate" palette while staying readable.
/// The legend below repeats each slice's exact shade next to its amount.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    required this.totalMinor,
  });

  final List<CategorySlice> slices;
  final int totalMinor;

  List<Color> _shadesFor(ChartColors chart) {
    final dark = chart.accent;
    final light = chart.soft;
    final count = slices.length;
    return List.generate(count, (i) {
      final t = count <= 1 ? 0.0 : (i / (count - 1)) * 0.75;
      return Color.lerp(dark, light, t)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shades = _shadesFor(ChartColors.of(context));
    final amountFormatter = appCurrency(symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CustomPaint(
                      size: const Size(168, 168),
                      painter: _DonutPainter(
                        fractions: [for (final s in slices) s.fraction],
                        colors: shades,
                        progress: value,
                        trackColor: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amountFormatter.format(totalMinor / 100),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: shades[i],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconForKey(slices[i].iconKey),
                    size: 16,
                    // Light slices (e.g. soft sky) need a dark glyph.
                    color: shades[i].computeLuminance() > 0.6
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    slices[i].label,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  amountFormatter.format(slices[i].amountMinor / 100),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(slices[i].fraction * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fractions,
    required this.colors,
    required this.progress,
    required this.trackColor,
  });

  final List<double> fractions;
  final List<Color> colors;
  final double progress;
  final Color trackColor;

  static const _strokeWidth = 18.0;
  static const _gapRadians = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    var start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 2 * math.pi * progress - _gapRadians;
      if (sweep <= 0) {
        start += fractions[i] * 2 * math.pi;
        continue;
      }
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += fractions[i] * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.fractions != fractions;
}
