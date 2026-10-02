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

/// Groups debit transactions by merchant and flags ones that repeat on a
/// roughly monthly cadence with a consistent amount — Netflix, utility
/// bills, rent, that kind of thing. Pure function over whatever
/// transactions are already loaded; cheap enough to recompute on every
/// change rather than caching.
List<RecurringInsight> detectRecurring(List<Transaction> transactions) {
  final byMerchant = <String, List<Transaction>>{};
  for (final t in transactions) {
    if (t.type != 'debit') continue;
    byMerchant.putIfAbsent(t.merchant.toLowerCase().trim(), () => []).add(t);
  }

  final insights = <RecurringInsight>[];
  for (final group in byMerchant.values) {
    if (group.length < 2) continue;
    group.sort((a, b) => a.date.compareTo(b.date));

    final intervals = <int>[];
    for (var i = 1; i < group.length; i++) {
      intervals.add(group[i].date.difference(group[i - 1].date).inDays);
    }
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    // A recurring bill lands roughly monthly — allow a wide-ish band since
    // real due dates drift by a few days month to month.
    if (avgInterval < 20 || avgInterval > 40) continue;

    final amounts = group.map((t) => t.amountMinor).toList();
    final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
    final maxDrift = amounts
        .map((a) => (a - avgAmount).abs())
        .reduce((a, b) => a > b ? a : b);
    if (maxDrift > avgAmount * 0.15) continue;

    final last = group.last;
    insights.add(
      RecurringInsight(
        merchant: last.merchant,
        categoryId: last.categoryId,
        expectedAmountMinor: avgAmount.round(),
        intervalDays: avgInterval.round(),
        lastDate: last.date,
        nextExpectedDate: last.date.add(Duration(days: avgInterval.round())),
      ),
    );
  }

  insights.sort((a, b) => a.nextExpectedDate.compareTo(b.nextExpectedDate));
  return insights;
}
