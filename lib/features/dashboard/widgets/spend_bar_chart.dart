import '../../../core/money_format.dart';
import 'package:flutter/material.dart';

import 'chart_buckets.dart';
import '../../../core/theme/app_theme.dart';

/// A bar chart of [buckets]: the current bucket is filled solid black
/// (white in dark mode) to draw the eye, the rest sit in flat neutral gray
/// — matching the "Uber Slate" monochrome palette. A dashed line marks the
/// average across all visible buckets, labeled with its amount.
class SpendBarChart extends StatelessWidget {
  const SpendBarChart({
    super.key,
    required this.buckets,
    this.barsHeight = 140,
  });

  final List<ChartBucket> buckets;
  final double barsHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAmount = buckets
        .map((b) => b.amountMinor)
        .fold<int>(0, (max, v) => v > max ? v : max);
    final average = buckets.isEmpty
        ? 0
        : buckets.fold<int>(0, (sum, b) => sum + b.amountMinor) ~/
              buckets.length;
    final amountFormatter = appCurrency(symbol: '₹',
      decimalDigits: 0,
    );
    final lineFraction = maxAmount == 0
        ? null
        : (average / maxAmount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: barsHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _Bar(
                          bucket: bucket,
                          maxAmount: maxAmount,
                          theme: theme,
                        ),
                      ),
                    ),
                ],
              ),
              // Painted after the bars so the dashed average line and its
              // label stay visible even when a bar is tall enough to reach
              // the same height.
              if (lineFraction != null && average > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: (barsHeight * (1 - lineFraction) - 18).clamp(
                    2.0,
                    barsHeight - 20,
                  ),
                  child: _AverageLine(
                    label: amountFormatter.format(average / 100),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final bucket in buckets)
              Expanded(
                child: Text(
                  bucket.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bucket.isCurrent
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: bucket.isCurrent
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({
    required this.bucket,
    required this.maxAmount,
    required this.theme,
  });

  final ChartBucket bucket;
  final int maxAmount;
  final ThemeData theme;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  // The full grow-in plays once; later changes (rows landing during an import)
  // glide briefly from the current height so the chart never looks stuck.
  bool _updated = false;

  @override
  void didUpdateWidget(_Bar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket.amountMinor != widget.bucket.amountMinor ||
        oldWidget.maxAmount != widget.maxAmount) {
      _updated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chart = ChartColors.of(context);
    final bucket = widget.bucket;
    final fraction = widget.maxAmount == 0
        ? 0.0
        : bucket.amountMinor / widget.maxAmount;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction.clamp(0.02, 1.0)),
      duration: Duration(milliseconds: _updated ? 220 : 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return FractionallySizedBox(
          heightFactor: value,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: bucket.isCurrent ? chart.accent : chart.soft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AverageLine extends StatelessWidget {
  const _AverageLine({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedLinePainter(color: color),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashGap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
