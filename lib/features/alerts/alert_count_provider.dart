import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/analytics/budget_status.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/lending/lending_math.dart';
import '../../core/lending/lending_repository.dart';
import '../../core/obligations/obligation_repository.dart';

/// How many things need attention, for the badge on the bell: failed
/// auto-debits, dues coming up, budgets at or over their limit, and lending
/// that is due soon. (The quieter insights on the Alerts screen don't count.)
final alertCountProvider = Provider<int>((ref) {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final budgetAlerts = budgetStatuses(
    budgets: ref.watch(monthBudgetsProvider(month)),
    transactions: ref.watch(analyticsTransactionsProvider),
    month: month,
  ).where((s) => s.level != BudgetLevel.ok).length;
  final lendingDue = dueSoon(ref.watch(lendingBalancesProvider), now).length;
  return ref.watch(recentFailuresProvider).length +
      ref.watch(upcomingObligationsProvider).length +
      budgetAlerts +
      lendingDue;
});
