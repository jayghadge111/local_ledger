import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/merchant_avatar.dart';
import 'widgets/chart_buckets.dart';
import 'widgets/date_range_chips.dart';
import 'widgets/spend_bar_chart.dart';

class _MerchantSpend {
  _MerchantSpend(this.merchant, this.categoryIconKey);
  final String merchant;
  final String? categoryIconKey;
  int amountMinor = 0;
  int purchases = 0;
}

/// Full-screen "drill down" on spend: the same chart as the dashboard card,
/// but with a date-range filter and a ranked list of merchants underneath —
/// reached by tapping the dashboard's spend trend card.
class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.transactions,
    required this.categoriesById,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  DateRangeFilter _filter = DateRangeFilter.sixMonths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final buckets = buildExpenseBuckets(widget.transactions, _filter, now);
    final (rangeStart, rangeEnd) = rangeFor(_filter, now);

    final inRange = widget.transactions.where(
      (t) =>
          t.type == 'debit' &&
          !t.date.isBefore(rangeStart) &&
          t.date.isBefore(rangeEnd),
    );
    final total = inRange.fold<int>(0, (sum, t) => sum + t.amountMinor);

    final byMerchant = <String, _MerchantSpend>{};
    for (final t in inRange) {
      final entry = byMerchant.putIfAbsent(
        t.merchant,
        () => _MerchantSpend(
          t.merchant,
          widget.categoriesById[t.categoryId]?.icon,
        ),
      );
      entry.amountMinor += t.amountMinor;
      entry.purchases += 1;
    }
    final topMerchants = byMerchant.values.toList()
      ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

    final amountFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return GlassBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('Expenses', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  FadeSlideIn(
                    child: Text(
                      _periodLabel(_filter, now),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 20),
                    child: Text(
                      amountFormatter.format(total / 100),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 40),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DateRangeChips(
                        selected: _filter,
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: SpendBarChart(buckets: buckets),
                  ),
                  const SizedBox(height: 32),
                  if (topMerchants.isNotEmpty) ...[
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Top stores',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < topMerchants.length && i < 10; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 90 + 20 * i),
                          child: Row(
                            children: [
                              MerchantAvatar(
                                merchant: topMerchants[i].merchant,
                                categoryIconKey:
                                    topMerchants[i].categoryIconKey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topMerchants[i].merchant,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      '${topMerchants[i].purchases} purchase${topMerchants[i].purchases == 1 ? '' : 's'}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                amountFormatter.format(
                                  topMerchants[i].amountMinor / 100,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(DateRangeFilter filter, DateTime now) {
    switch (filter) {
      case DateRangeFilter.week:
        return 'Last 7 days';
      case DateRangeFilter.month:
        return DateFormat.MMMM().format(now);
      case DateRangeFilter.threeMonths:
        return 'Last 3 months';
      case DateRangeFilter.sixMonths:
        return 'Last 6 months';
      case DateRangeFilter.year:
        return 'Last 12 months';
      case DateRangeFilter.all:
        return 'All time';
    }
  }
}
