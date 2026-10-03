import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/providers.dart';

DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

/// The month Home (totals, category chart, budgets) is showing. Starts on the
/// current month; the user can step back or pick any month that has data.
class DashboardMonth extends Notifier<DateTime> {
  @override
  DateTime build() => monthOf(DateTime.now());

  void select(DateTime month) {
    final m = monthOf(month);
    final current = monthOf(DateTime.now());
    state = m.isAfter(current) ? current : m;
  }

  void previous() => select(DateTime(state.year, state.month - 1));
  void next() => select(DateTime(state.year, state.month + 1));
  void reset() => state = monthOf(DateTime.now());
}

final dashboardMonthProvider = NotifierProvider<DashboardMonth, DateTime>(
  DashboardMonth.new,
);

/// The oldest month with a transaction (or the current month if none) — the
/// earliest the picker offers.
final earliestMonthProvider = Provider<DateTime>((ref) {
  final all = ref.watch(transactionsProvider).value;
  final current = monthOf(DateTime.now());
  if (all == null || all.isEmpty) return current;
  var earliest = all.first.date;
  for (final t in all) {
    if (t.date.isBefore(earliest)) earliest = t.date;
  }
  final m = monthOf(earliest);
  return m.isAfter(current) ? current : m;
});

bool isCurrentMonth(DateTime month) =>
    monthOf(month) == monthOf(DateTime.now());

/// "October 2026".
String monthYearLabel(DateTime month) => DateFormat('MMMM yyyy').format(month);

/// "this month", or "October 2026" — for sentences like "Spent in …".
String monthPhrase(DateTime month) => isCurrentMonth(month)
    ? 'this month'
    : 'in ${DateFormat('MMM yyyy').format(month)}';
