import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';

/// The date-range filters shown as chips above a spend chart.
enum DateRangeFilter { week, month, threeMonths, sixMonths, year, all }

extension DateRangeFilterLabel on DateRangeFilter {
  String get chipLabel => switch (this) {
    DateRangeFilter.week => 'W',
    DateRangeFilter.month => 'M',
    DateRangeFilter.threeMonths => '3M',
    DateRangeFilter.sixMonths => '6M',
    DateRangeFilter.year => 'Y',
    DateRangeFilter.all => 'All',
  };
}

/// One bar's worth of aggregated debit spend.
class ChartBucket {
  const ChartBucket({
    required this.label,
    required this.amountMinor,
    required this.isCurrent,
  });

  final String label;
  final int amountMinor;
  final bool isCurrent;
}

/// Buckets [transactions]' debit spend into bars for [filter], anchored at
/// [now]. Each filter picks a granularity that keeps the bar count small
/// enough to render without scrolling: days for a week, weeks for a month,
/// months otherwise.
List<ChartBucket> buildExpenseBuckets(
  List<Transaction> transactions,
  DateRangeFilter filter,
  DateTime now,
) {
  switch (filter) {
    case DateRangeFilter.week:
      return _dailyBuckets(transactions, now, days: 7);
    case DateRangeFilter.month:
      return _weeklyBucketsForMonth(transactions, now);
    case DateRangeFilter.threeMonths:
      return _monthlyBuckets(transactions, now, months: 3);
    case DateRangeFilter.sixMonths:
      return _monthlyBuckets(transactions, now, months: 6);
    case DateRangeFilter.year:
      return _monthlyBuckets(transactions, now, months: 12);
    case DateRangeFilter.all:
      if (transactions.isEmpty) {
        return _monthlyBuckets(transactions, now, months: 6);
      }
      final earliest = transactions
          .map((t) => t.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final span =
          (now.year - earliest.year) * 12 + (now.month - earliest.month) + 1;
      return _monthlyBuckets(transactions, now, months: span.clamp(1, 12));
  }
}

/// The [start, endExclusive) window a filter covers, anchored at [now] —
/// used to scope things other than the chart itself (e.g. a "top
/// merchants" list) to the same period the chips show.
(DateTime, DateTime) rangeFor(DateRangeFilter filter, DateTime now) {
  final endExclusive = DateTime(now.year, now.month, now.day + 1);
  switch (filter) {
    case DateRangeFilter.week:
      return (endExclusive.subtract(const Duration(days: 7)), endExclusive);
    case DateRangeFilter.month:
      return (DateTime(now.year, now.month, 1), endExclusive);
    case DateRangeFilter.threeMonths:
      return (DateTime(now.year, now.month - 2, 1), endExclusive);
    case DateRangeFilter.sixMonths:
      return (DateTime(now.year, now.month - 5, 1), endExclusive);
    case DateRangeFilter.year:
      return (DateTime(now.year, now.month - 11, 1), endExclusive);
    case DateRangeFilter.all:
      return (DateTime(2000), endExclusive);
  }
}

int _debitSum(
  List<Transaction> transactions,
  DateTime start,
  DateTime endExclusive,
) {
  return transactions
      .where(
        (t) =>
            t.type == 'debit' &&
            !t.date.isBefore(start) &&
            t.date.isBefore(endExclusive),
      )
      .fold<int>(0, (sum, t) => sum + t.amountMinor);
}

List<ChartBucket> _dailyBuckets(
  List<Transaction> transactions,
  DateTime now, {
  required int days,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final buckets = <ChartBucket>[];
  for (var i = days - 1; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final next = day.add(const Duration(days: 1));
    buckets.add(
      ChartBucket(
        label: DateFormat.E().format(day).substring(0, 1),
        amountMinor: _debitSum(transactions, day, next),
        isCurrent: i == 0,
      ),
    );
  }
  return buckets;
}

List<ChartBucket> _weeklyBucketsForMonth(
  List<Transaction> transactions,
  DateTime now,
) {
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final buckets = <ChartBucket>[];
  var weekIndex = 1;
  for (
    var dayOfMonth = 1;
    dayOfMonth <= daysInMonth;
    dayOfMonth += 7, weekIndex++
  ) {
    final start = DateTime(now.year, now.month, dayOfMonth);
    final end = DateTime(
      now.year,
      now.month,
      (dayOfMonth + 7).clamp(1, daysInMonth + 1),
    );
    final isCurrent = !now.isBefore(start) && now.isBefore(end);
    buckets.add(
      ChartBucket(
        label: 'W$weekIndex',
        amountMinor: _debitSum(transactions, start, end),
        isCurrent: isCurrent,
      ),
    );
  }
  return buckets;
}

List<ChartBucket> _monthlyBuckets(
  List<Transaction> transactions,
  DateTime now, {
  required int months,
}) {
  final buckets = <ChartBucket>[];
  for (var i = months - 1; i >= 0; i--) {
    final target = DateTime(now.year, now.month - i, 1);
    final next = DateTime(target.year, target.month + 1, 1);
    buckets.add(
      ChartBucket(
        label: DateFormat.MMM().format(target),
        amountMinor: _debitSum(transactions, target, next),
        isCurrent: i == 0,
      ),
    );
  }
  return buckets;
}
