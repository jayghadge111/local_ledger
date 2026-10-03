import '../analytics/budget_status.dart';

/// A budget threshold crossed that the user has not been told about yet.
class BudgetAlert {
  const BudgetAlert({
    required this.status,
    required this.level,
    required this.key,
  });

  final BudgetStatus status;
  final BudgetLevel level; // warning | over
  final String key;
}

/// The alert key for one category, level and month — remembered once shown so
/// each threshold is announced once per month, however many transactions
/// follow.
String budgetAlertKey(DateTime month, String categoryId, BudgetLevel level) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}|$categoryId|${level.name}';

/// Which thresholds in [statuses] (for [month]) are new. A category already
/// over its limit is announced as "over" only — not also as a warning.
List<BudgetAlert> newBudgetAlerts(
  List<BudgetStatus> statuses,
  DateTime month,
  Set<String> alreadyShown,
) {
  final alerts = <BudgetAlert>[];
  for (final s in statuses) {
    if (s.level == BudgetLevel.ok) continue;
    final key = budgetAlertKey(month, s.categoryId, s.level);
    if (alreadyShown.contains(key)) continue;
    alerts.add(BudgetAlert(status: s, level: s.level, key: key));
  }
  return alerts;
}

/// Drops remembered keys from other months so the list doesn't grow forever.
Set<String> keysForMonth(Set<String> keys, DateTime month) {
  final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}|';
  return {
    for (final k in keys)
      if (k.startsWith(prefix)) k,
  };
}
