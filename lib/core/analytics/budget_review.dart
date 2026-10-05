import '../db/app_database.dart';
import 'budget_status.dart';

/// One category that went over its budget in the month that just ended.
class ReviewItem {
  const ReviewItem({
    required this.categoryId,
    required this.limitMinor,
    required this.spentMinor,
    required this.suggestedMinor,
  });

  final String categoryId;
  final int limitMinor;
  final int spentMinor;

  /// A limit that would have covered it, to offer in one tap.
  final int suggestedMinor;

  double get fraction => limitMinor <= 0 ? 0 : spentMinor / limitMinor;
}

/// How last month went against its budgets.
class BudgetReview {
  const BudgetReview({
    required this.month,
    required this.totalBudgets,
    required this.over,
  });

  /// The month that ended.
  final DateTime month;
  final int totalBudgets;

  /// Categories that went over, worst first.
  final List<ReviewItem> over;

  int get overCount => over.length;
  bool get allWithinLimits => over.isEmpty;
}

/// The review of [month] (the month that just ended), or null if it had no
/// budgets. [budgetsLastMonth] are the budgets that were in force then;
/// [transactions] should be the analytics view.
BudgetReview? buildBudgetReview({
  required List<Budget> budgetsLastMonth,
  required List<Transaction> transactions,
  required DateTime month,
  int averageOverMonths = 3,
}) {
  if (budgetsLastMonth.isEmpty) return null;
  final statuses = budgetStatuses(
    budgets: budgetsLastMonth,
    transactions: transactions,
    month: month,
  );
  final over = <ReviewItem>[
    for (final s in statuses)
      if (s.isOver)
        ReviewItem(
          categoryId: s.categoryId,
          limitMinor: s.limitMinor,
          spentMinor: s.spentMinor,
          suggestedMinor: suggestedLimit(
            limitMinor: s.limitMinor,
            lastMonthSpentMinor: s.spentMinor,
            averageSpentMinor: _averageSpend(
              transactions,
              s.categoryId,
              month,
              averageOverMonths,
            ),
          ),
        ),
  ];
  return BudgetReview(
    month: month,
    totalBudgets: budgetsLastMonth.length,
    over: over,
  );
}

/// A limit that covers what the category really costs: the recent average if
/// that is above the current limit, otherwise last month's spend, rounded up
/// to a tidy figure. Always above the old limit.
int suggestedLimit({
  required int limitMinor,
  required int lastMonthSpentMinor,
  required int averageSpentMinor,
}) {
  final base = averageSpentMinor > limitMinor
      ? averageSpentMinor
      : lastMonthSpentMinor;
  return roundUpLimit(base);
}

/// Up to the next ₹100 (₹500 once it reaches ₹5,000).
int roundUpLimit(int minor) {
  final rupees = (minor / 100).ceil();
  final step = rupees >= 5000 ? 500 : 100;
  return ((rupees / step).ceil() * step) * 100;
}

int _averageSpend(
  List<Transaction> transactions,
  String categoryId,
  DateTime lastMonth,
  int months,
) {
  var total = 0;
  for (var i = 0; i < months; i++) {
    final m = DateTime(lastMonth.year, lastMonth.month - i);
    for (final t in transactions) {
      if (t.type == 'debit' &&
          (t.categoryId ?? 'cat_other') == categoryId &&
          t.date.year == m.year &&
          t.date.month == m.month) {
        total += t.amountMinor;
      }
    }
  }
  return (total / months).round();
}

/// Whether the review card should be on Home: something went over, it is early
/// in the new month, and the user has not put it away for this month.
bool shouldShowReview({
  required BudgetReview? review,
  required DateTime now,
  required String? dismissedForMonthKey,
  required String currentMonthKey,
  int visibleForDays = 5,
}) {
  if (review == null || review.allWithinLimits) return false;
  if (now.day > visibleForDays) return false;
  return dismissedForMonthKey != currentMonthKey;
}

/// The notification at the start of a month, e.g.
/// ("September budgets", "3 of 12 went over: Food, Shopping, Fuel.").
({String title, String body}) monthSummaryText(
  BudgetReview review,
  String Function(String categoryId) nameOf,
  String monthName,
) {
  final title = '$monthName budgets';
  if (review.allWithinLimits) {
    return (
      title: title,
      body: review.totalBudgets == 1
          ? 'Your budget stayed within its limit.'
          : 'All ${review.totalBudgets} budgets stayed within their limits.',
    );
  }
  final names = review.over.take(3).map((i) => nameOf(i.categoryId)).toList();
  final more = review.overCount - names.length;
  final list = more > 0
      ? '${names.join(', ')} and $more more'
      : names.join(', ');
  return (
    title: title,
    body: '${review.overCount} of ${review.totalBudgets} went over: $list.',
  );
}
