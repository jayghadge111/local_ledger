import '../db/app_database.dart';

enum BudgetLevel { ok, warning, over }

/// One category's budget against what was spent in a month.
class BudgetStatus {
  const BudgetStatus({
    required this.categoryId,
    required this.limitMinor,
    required this.spentMinor,
  });

  final String categoryId;
  final int limitMinor;
  final int spentMinor;

  double get fraction => limitMinor <= 0 ? 0 : spentMinor / limitMinor;
  bool get isOver => spentMinor > limitMinor;
  int get overByMinor => isOver ? spentMinor - limitMinor : 0;
  int get remainingMinor => isOver ? 0 : limitMinor - spentMinor;

  /// Warning from 80% of the limit; over once it is passed.
  BudgetLevel get level => isOver
      ? BudgetLevel.over
      : fraction >= 0.8
      ? BudgetLevel.warning
      : BudgetLevel.ok;
}

/// Budget vs. spend for every budgeted category in [month], worst first
/// (over budget, then closest to the limit). [transactions] should already be
/// the analytics view (no transfers, refunds netted, splits at the user's
/// share).
List<BudgetStatus> budgetStatuses({
  required List<Budget> budgets,
  required List<Transaction> transactions,
  required DateTime month,
}) {
  final spent = <String, int>{};
  for (final t in transactions) {
    if (t.type != 'debit' ||
        t.date.year != month.year ||
        t.date.month != month.month) {
      continue;
    }
    spent.update(
      t.categoryId ?? 'cat_other',
      (v) => v + t.amountMinor,
      ifAbsent: () => t.amountMinor,
    );
  }
  final list = [
    for (final b in budgets)
      BudgetStatus(
        categoryId: b.categoryId,
        limitMinor: b.monthlyLimitMinor,
        spentMinor: spent[b.categoryId] ?? 0,
      ),
  ]..sort((a, b) => b.fraction.compareTo(a.fraction));
  return list;
}
