import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/db/providers.dart';
import 'dashboard_month.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/chart_buckets.dart';

/// Everything Home shows that is computed from the month's transactions.
///
/// It lives in a provider rather than in the screen's `build` so the passes
/// over the whole transaction list run once per change of data or month, not
/// on every rebuild of the page.
class DashboardSummary {
  const DashboardSummary({
    required this.spentMinor,
    required this.receivedMinor,
    required this.slices,
    required this.buckets,
  });

  final int spentMinor;
  final int receivedMinor;

  /// The five biggest spending categories.
  final List<CategorySlice> slices;

  /// Six months of spend ending at the month on screen.
  final List<ChartBucket> buckets;

  bool get hasTrendData => buckets.any((b) => b.amountMinor > 0);
}

final dashboardSummaryProvider = Provider.family<DashboardSummary, DateTime>((
  ref,
  month,
) {
  final analytics = ref.watch(analyticsTransactionsProvider);
  final categories = {
    for (final c in ref.watch(categoriesProvider).value ?? const []) c.id: c,
  };

  var spent = 0;
  var received = 0;
  final byCategory = <String, int>{};
  for (final t in analytics) {
    if (t.date.year != month.year || t.date.month != month.month) continue;
    if (t.type == 'debit') {
      spent += t.amountMinor;
      byCategory.update(
        t.categoryId ?? 'cat_other',
        (v) => v + t.amountMinor,
        ifAbsent: () => t.amountMinor,
      );
    } else if (t.type == 'credit') {
      received += t.amountMinor;
    }
  }

  final top = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final slices = [
    for (final entry in top.take(5))
      CategorySlice(
        label: categories[entry.key]?.name ?? 'Uncategorized',
        iconKey: categories[entry.key]?.icon,
        amountMinor: entry.value,
        fraction: spent == 0 ? 0 : entry.value / spent,
      ),
  ];

  // The trend ends at the month on screen (its last day for a past month).
  final anchor = isCurrentMonth(month)
      ? DateTime.now()
      : DateTime(month.year, month.month + 1, 0);
  return DashboardSummary(
    spentMinor: spent,
    receivedMinor: received,
    slices: slices,
    buckets: buildExpenseBuckets(analytics, DateRangeFilter.sixMonths, anchor),
  );
});
