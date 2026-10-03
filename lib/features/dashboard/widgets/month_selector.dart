import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/centered_dialog_card.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../dashboard_month.dart';

/// "‹  October 2026 ▾  ›" — step month by month, or tap the label to pick any
/// month and year that has data.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(dashboardMonthProvider);
    final earliest = ref.watch(earliestMonthProvider);
    final notifier = ref.read(dashboardMonthProvider.notifier);
    final canGoBack = month.isAfter(earliest);
    final canGoForward = !isCurrentMonth(month);

    return Row(
      children: [
        _StepButton(
          icon: Icons.chevron_left_rounded,
          onPressed: canGoBack ? notifier.previous : null,
          tooltip: 'Previous month',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showMonthPicker(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      monthYearLabel(month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _StepButton(
          icon: Icons.chevron_right_rounded,
          onPressed: canGoForward ? notifier.next : null,
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

Future<void> showMonthPicker(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const CenteredDialogCard(child: _MonthPickerCard()),
  );
}

class _MonthPickerCard extends ConsumerStatefulWidget {
  const _MonthPickerCard();

  @override
  ConsumerState<_MonthPickerCard> createState() => _MonthPickerCardState();
}

class _MonthPickerCardState extends ConsumerState<_MonthPickerCard> {
  late int _year = ref.read(dashboardMonthProvider).year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(dashboardMonthProvider);
    final earliest = ref.watch(earliestMonthProvider);
    final current = monthOf(DateTime.now());
    final years = [for (var y = current.year; y >= earliest.year; y--) y];
    if (!years.contains(_year)) _year = years.first;

    bool enabled(int month) {
      final m = DateTime(_year, month);
      return !m.isBefore(earliest) && !m.isAfter(current);
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
                    Expanded(
                      child: Text(
                        'Choose a month',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
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
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                  items: [
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
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
                        selected: selected.year == _year && selected.month == m,
                        enabled: enabled(m),
                        onTap: () {
                          ref
                              .read(dashboardMonthProvider.notifier)
                              .select(DateTime(_year, m));
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(dashboardMonthProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
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
      color: selected ? scheme.onSurface : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.onSurface : scheme.outlineVariant,
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
                  ? scheme.surface
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
