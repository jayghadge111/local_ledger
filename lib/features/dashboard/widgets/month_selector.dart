import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/centered_dialog_card.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../dashboard_month.dart';

/// "‹  October 2026 ▾  ›" for Home: steps the dashboard month.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MonthNavigator(
      month: ref.watch(dashboardMonthProvider),
      earliest: ref.watch(earliestMonthProvider),
      onChanged: ref.read(dashboardMonthProvider.notifier).select,
    );
  }
}

/// Step month by month, or tap the label to pick any month and year between
/// [earliest] and the current month.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({super.key, required this.month, required this.earliest, required this.onChanged});

  final DateTime month;
  final DateTime earliest;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = month.isAfter(earliest);
    final canGoForward = !isCurrentMonth(month);

    return Row(
      children: [
        _StepButton(
          icon: Icons.chevron_left_rounded,
          onPressed: canGoBack ? () => onChanged(DateTime(month.year, month.month - 1)) : null,
          tooltip: 'Previous month',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await pickMonth(context, selected: month, earliest: earliest);
              if (picked != null) onChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      monthYearLabel(month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _StepButton(
          icon: Icons.chevron_right_rounded,
          onPressed: canGoForward ? () => onChanged(DateTime(month.year, month.month + 1)) : null,
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

/// Asks for a month and year; null if dismissed.
Future<DateTime?> pickMonth(BuildContext context, {required DateTime selected, required DateTime earliest}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => CenteredDialogCard(child: _MonthPickerCard(selected: selected, earliest: earliest)),
  );
}

class _MonthPickerCard extends StatefulWidget {
  const _MonthPickerCard({required this.selected, required this.earliest});

  final DateTime selected;
  final DateTime earliest;

  @override
  State<_MonthPickerCard> createState() => _MonthPickerCardState();
}

class _MonthPickerCardState extends State<_MonthPickerCard> {
  late int _year = widget.selected.year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = monthOf(DateTime.now());
    final years = [for (var y = current.year; y >= widget.earliest.year; y--) y];
    if (!years.contains(_year)) _year = years.first;

    bool enabled(int month) {
      final m = DateTime(_year, month);
      return !m.isBefore(widget.earliest) && !m.isAfter(current);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Choose a month', style: theme.textTheme.titleLarge)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(labelText: 'Year', prefixIcon: Icon(Icons.event_rounded)),
                  items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                  onChanged: (y) => setState(() => _year = y ?? _year),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.7,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      _MonthCell(
                        label: DateFormat.MMM().format(DateTime(2000, m)),
                        selected: widget.selected.year == _year && widget.selected.month == m,
                        enabled: enabled(m),
                        onTap: () => Navigator.of(context).pop(DateTime(_year, m)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(current),
                  icon: const Icon(Icons.today_rounded),
                  label: const Text('This month'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.secondary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? scheme.onSecondary
                  : enabled
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.28),
            ),
          ),
        ),
      ),
    );
  }
}
