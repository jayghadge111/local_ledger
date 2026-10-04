import 'package:flutter/material.dart';

import 'chart_buckets.dart';

/// The W / M / 3M / 6M / Y / All filter row shown above a spend chart.
/// Selected chip is solid black (white in dark mode); the rest are flat
/// neutral gray pills — same monochrome treatment as the chart bars.
class DateRangeChips extends StatelessWidget {
  const DateRangeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DateRangeFilter selected;
  final ValueChanged<DateRangeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final filter in DateRangeFilter.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: filter.chipLabel,
              selected: filter == selected,
              onTap: () => onChanged(filter),
              theme: theme,
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? theme.colorScheme.secondary
          : theme.colorScheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onSecondary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
