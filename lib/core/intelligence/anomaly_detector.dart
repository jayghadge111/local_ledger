import '../db/app_database.dart';

/// A transaction is "unusual" if it was explicitly flagged (manual entry or
/// import), or if it's a debit well above the typical spend in its own
/// category — more than 3x the median of the other debits in that
/// category, with at least 3 other data points so the comparison means
/// something.
List<Transaction> detectUnusual(List<Transaction> transactions) {
  final debitsByCategory = <String, List<int>>{};
  for (final t in transactions) {
    if (t.type != 'debit') continue;
    debitsByCategory
        .putIfAbsent(t.categoryId ?? 'cat_other', () => [])
        .add(t.amountMinor);
  }

  int median(List<int> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }

  final unusual = <Transaction>[];
  for (final t in transactions) {
    if (t.isFlaggedUnusual) {
      unusual.add(t);
      continue;
    }
    if (t.type != 'debit') continue;

    final categoryAmounts = debitsByCategory[t.categoryId ?? 'cat_other'] ?? [];
    final others = [...categoryAmounts]..remove(t.amountMinor);
    if (others.length < 3) continue;

    final typical = median(others);
    if (typical > 0 && t.amountMinor > typical * 3) {
      unusual.add(t);
    }
  }

  unusual.sort((a, b) => b.date.compareTo(a.date));
  return unusual;
}

List<Transaction> detectInternational(List<Transaction> transactions) {
  final flagged = transactions.where((t) => t.isInternational).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return flagged;
}
