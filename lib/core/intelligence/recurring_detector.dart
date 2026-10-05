import '../db/app_database.dart';

class RecurringInsight {
  const RecurringInsight({
    required this.merchant,
    required this.categoryId,
    required this.expectedAmountMinor,
    required this.intervalDays,
    required this.lastDate,
    required this.nextExpectedDate,
  });

  final String merchant;
  final String? categoryId;
  final int expectedAmountMinor;
  final int intervalDays;
  final DateTime lastDate;
  final DateTime nextExpectedDate;

  int get daysUntilDue => nextExpectedDate.difference(DateTime.now()).inDays;
}

/// Flags payments that repeat once a month — bills, subscriptions,
/// recharges, EMIs, rent.
///
/// A merchant counts only if its most recent payments (up to six) each
/// follow the previous one by about a month (24-38 days) with a similar
/// amount. Judging every gap, rather than the average, is what keeps a cafe
/// you visit daily out of the list: one day-to-day gap rules it out, however
/// the rest average. At least three payments are needed, and the last one
/// must be recent so cancelled subscriptions drop off.
List<RecurringInsight> detectRecurring(
  List<Transaction> transactions, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  final byMerchant = <String, List<Transaction>>{};
  for (final t in transactions) {
    if (t.type != 'debit') continue;
    byMerchant.putIfAbsent(t.merchant.toLowerCase().trim(), () => []).add(t);
  }

  final insights = <RecurringInsight>[];
  for (final entries in byMerchant.values) {
    if (entries.length < 3) continue;
    entries.sort((a, b) => a.date.compareTo(b.date));
    final recent = entries.length > 6
        ? entries.sublist(entries.length - 6)
        : entries;

    final gaps = <int>[
      for (var i = 1; i < recent.length; i++)
        day(recent[i].date).difference(day(recent[i - 1].date)).inDays,
    ];
    if (gaps.any((g) => g < _minGapDays || g > _maxGapDays)) continue;

    final amounts = recent.map((t) => t.amountMinor).toList();
    final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
    final maxDrift = amounts
        .map((a) => (a - avgAmount).abs())
        .reduce((a, b) => a > b ? a : b);
    if (maxDrift > avgAmount * _maxAmountDrift) continue;

    final last = recent.last;
    if (day(today).difference(day(last.date)).inDays > _maxDaysSinceLast)
      continue;

    final sortedGaps = [...gaps]..sort();
    final typicalGap = sortedGaps[sortedGaps.length ~/ 2];
    insights.add(
      RecurringInsight(
        merchant: last.merchant,
        categoryId: last.categoryId,
        expectedAmountMinor: avgAmount.round(),
        intervalDays: typicalGap,
        lastDate: last.date,
        nextExpectedDate: last.date.add(Duration(days: typicalGap)),
      ),
    );
  }

  insights.sort((a, b) => a.nextExpectedDate.compareTo(b.nextExpectedDate));
  return insights;
}

// Real due dates drift a few days (weekends, 28-31 day months).
const _minGapDays = 24;
const _maxGapDays = 38;
const _maxAmountDrift = 0.25;
const _maxDaysSinceLast = 60;
