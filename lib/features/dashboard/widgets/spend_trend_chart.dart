import 'package:flutter/material.dart';

class MonthSpend {
  const MonthSpend(this.label, this.amountMinor);
  final String label;
  final int amountMinor;
}

/// Last few months' total spend as simple animated vertical bars — enough
/// to show a trend at a glance without pulling in a charting dependency.
class SpendTrendChart extends StatelessWidget {
  const SpendTrendChart({super.key, required this.months});

  final List<MonthSpend> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAmount = months.map((m) => m.amountMinor).fold<int>(
          0,
          (max, v) => v > max ? v : max,
        );

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final month in months)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxAmount == 0 ? 0 : month.amountMinor / maxAmount,
                      ),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox(
                          height: 96,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: value.clamp(0.03, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      month.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
