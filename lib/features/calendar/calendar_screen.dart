import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../dashboard/dashboard_month.dart';
import '../dashboard/widgets/month_selector.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/widgets/transaction_tile.dart';
import 'calendar_math.dart';
import '../../core/theme/app_theme.dart';

/// A month at a glance: what was spent and received on each day, and the
/// month's totals. Tap a day to list its transactions below.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.initialMonth});

  final DateTime? initialMonth;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = monthOf(widget.initialMonth ?? DateTime.now());
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (monthOf(now) == _month) {
      _selected = DateTime(now.year, now.month, now.day);
    }
  }

  void _changeMonth(DateTime m) {
    final now = DateTime.now();
    setState(() {
      _month = monthOf(m);
      _selected = monthOf(now) == _month
          ? DateTime(now.year, now.month, now.day)
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analytics = ref.watch(analyticsTransactionsProvider);
    final all = ref.watch(transactionsProvider).value ?? const <Transaction>[];
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final earliest = ref.watch(earliestMonthProvider);
    final totals = dayTotals(analytics, _month);
    final spent = totals.values.fold<int>(0, (s, d) => s + d.spentMinor);
    final received = totals.values.fold<int>(0, (s, d) => s + d.receivedMinor);
    final maxSpent = totals.values.fold<int>(
      0,
      (m, d) => d.spentMinor > m ? d.spentMinor : m,
    );
    final cells = monthGrid(_month);
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final dayList = _selected == null
        ? const <Transaction>[]
        : (all
              .where(
                (t) => !t.isDeleted && DateUtils.isSameDay(t.date, _selected),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)));
    final selectedTotals = _selected == null ? null : totals[_selected!.day];

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Calendar')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            MonthNavigator(
              month: _month,
              earliest: earliest,
              onChanged: _changeMonth,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Spent',
                    value: money.format(spent / 100),
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'Received',
                    value: money.format(received / 100),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'Net',
                    value:
                        '${received >= spent ? '+' : '-'}${money.format((received - spent).abs() / 100)}',
                    color: received >= spent
                        ? Colors.green
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final d in const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ])
                        Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.72,
                    children: [
                      for (final day in cells)
                        if (day == null)
                          const SizedBox.shrink()
                        else
                          _DayCell(
                            day: day,
                            totals: totals[day.day],
                            heat: maxSpent == 0
                                ? 0
                                : (totals[day.day]?.spentMinor ?? 0) / maxSpent,
                            isToday: DateUtils.isSameDay(day, DateTime.now()),
                            isSelected:
                                _selected != null &&
                                DateUtils.isSameDay(day, _selected),
                            onTap: () => setState(
                              () => _selected =
                                  (_selected != null &&
                                      DateUtils.isSameDay(day, _selected))
                                  ? null
                                  : day,
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selected == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tap a day to see its transactions.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM').format(_selected!),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (selectedTotals != null && !selectedTotals.isEmpty)
                    Text(
                      [
                        if (selectedTotals.spentMinor > 0)
                          '-${money.format(selectedTotals.spentMinor / 100)}',
                        if (selectedTotals.receivedMinor > 0)
                          '+${money.format(selectedTotals.receivedMinor / 100)}',
                      ].join('  '),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (dayList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No transactions on this day.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final t in dayList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TransactionTile(
                    transaction: t,
                    category: categories[t.categoryId],
                    onTap: () => showTransactionDetail(context, t),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.totals,
    required this.heat,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final DayTotals? totals;
  final double heat;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spent = totals?.spentMinor ?? 0;
    final received = totals?.receivedMinor ?? 0;
    final bg = isSelected
        ? scheme.secondary
        : ChartColors.of(context).accent
              .withValues(alpha: spent == 0 ? 0 : 0.05 + 0.25 * heat);
    final fg = isSelected ? scheme.onSecondary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isToday && !isSelected
              ? BorderSide(color: ChartColors.of(context).accent, width: 1.4)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                if (spent > 0)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '-${compactMoney(spent)}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                if (received > 0)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+${compactMoney(received)}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
