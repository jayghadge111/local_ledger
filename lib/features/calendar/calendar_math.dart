import '../../core/db/app_database.dart';

class DayTotals {
  const DayTotals({this.spentMinor = 0, this.receivedMinor = 0});

  final int spentMinor;
  final int receivedMinor;

  bool get isEmpty => spentMinor == 0 && receivedMinor == 0;
}

/// Spent / received per day of [month] (day number → totals). Pass the
/// analytics view so transfers and split shares are treated as on Home.
Map<int, DayTotals> dayTotals(List<Transaction> transactions, DateTime month) {
  final spent = <int, int>{};
  final received = <int, int>{};
  for (final t in transactions) {
    if (t.date.year != month.year || t.date.month != month.month) continue;
    final map = t.type == 'debit' ? spent : received;
    map.update(
      t.date.day,
      (v) => v + t.amountMinor,
      ifAbsent: () => t.amountMinor,
    );
  }
  return {
    for (final d in {...spent.keys, ...received.keys})
      d: DayTotals(spentMinor: spent[d] ?? 0, receivedMinor: received[d] ?? 0),
  };
}

/// The cells of a month grid, Monday first: leading nulls pad the first week,
/// then one entry per day.
List<DateTime?> monthGrid(DateTime month) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final lead = first.weekday - 1; // Monday = 1
  return [
    for (var i = 0; i < lead; i++) null,
    for (var d = 1; d <= days; d++) DateTime(month.year, month.month, d),
  ];
}

/// Short rupee amounts for tight spaces: ₹850, ₹1.2k, ₹45k, ₹1.2L, ₹3.5Cr.
String compactMoney(int minor) {
  final rupees = minor / 100;
  String trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (rupees < 1000) return '₹${rupees.round()}';
  if (rupees < 100000) return '₹${trim(rupees / 1000)}k';
  if (rupees < 10000000) return '₹${trim(rupees / 100000)}L';
  return '₹${trim(rupees / 10000000)}Cr';
}
