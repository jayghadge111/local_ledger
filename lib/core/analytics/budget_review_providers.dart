import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/budgets_repository.dart';
import '../db/settings_repository.dart';
import 'analytics_providers.dart';
import 'budget_review.dart';

/// How last month went against the budgets that were in force then. Null if
/// last month had no budgets.
final budgetReviewProvider = Provider<BudgetReview?>((ref) {
  final now = DateTime.now();
  final last = DateTime(now.year, now.month - 1);
  return buildBudgetReview(
    budgetsLastMonth: ref.watch(monthBudgetsProvider(last)),
    transactions: ref.watch(analyticsTransactionsProvider),
    month: last,
  );
});

/// The month key the review card was put away for, if any.
final budgetReviewDismissedProvider = StreamProvider<String?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsKeys.budgetReviewDismissed);
});
