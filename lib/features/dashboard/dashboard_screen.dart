import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../shared/widgets/animated_amount.dart';
import '../../shared/widgets/category_icons.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/placeholder_body.dart';
import '../transactions/widgets/transaction_tile.dart';
import 'widgets/spend_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const PlaceholderBody(
            icon: Icons.dashboard_outlined,
            title: 'Welcome to LocalLedger',
            subtitle:
                'Add a transaction (or load sample data from Settings) to see your dashboard come alive.',
          );
        }

        final categoriesById = {
          for (final c in categoriesAsync.value ?? <Category>[])
            c.id: c,
        };

        final now = DateTime.now();
        final thisMonth = transactions.where(
          (t) => t.date.year == now.year && t.date.month == now.month,
        );
        final spent = thisMonth
            .where((t) => t.type == 'debit')
            .fold<int>(0, (sum, t) => sum + t.amountMinor);
        final received = thisMonth
            .where((t) => t.type == 'credit')
            .fold<int>(0, (sum, t) => sum + t.amountMinor);

        final byCategory = <String, int>{};
        for (final t in thisMonth.where((t) => t.type == 'debit')) {
          byCategory.update(
            t.categoryId ?? 'cat_other',
            (v) => v + t.amountMinor,
            ifAbsent: () => t.amountMinor,
          );
        }
        final topCategories = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxCategorySpend =
            topCategories.isEmpty ? 1 : topCategories.first.value;

        final recent = transactions.take(5).toList();

        final monthSpends = <MonthSpend>[];
        for (var i = 5; i >= 0; i--) {
          final target = DateTime(now.year, now.month - i, 1);
          final total = transactions
              .where((t) =>
                  t.type == 'debit' &&
                  t.date.year == target.year &&
                  t.date.month == target.month)
              .fold<int>(0, (sum, t) => sum + t.amountMinor);
          monthSpends.add(MonthSpend(DateFormat.MMM().format(target), total));
        }
        final hasTrendData = monthSpends.any((m) => m.amountMinor > 0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            FadeSlideIn(child: _SummaryRow(spentMinor: spent, receivedMinor: received)),
            const SizedBox(height: 16),
            if (hasTrendData)
              FadeSlideIn(
                delay: const Duration(milliseconds: 45),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spend trend', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SpendTrendChart(months: monthSpends),
                    ],
                  ),
                ),
              ),
            if (hasTrendData) const SizedBox(height: 16),
            if (topCategories.isNotEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This month by category',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      for (final entry in topCategories.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryBar(
                            category: categoriesById[entry.key],
                            amountMinor: entry.value,
                            fraction: entry.value / maxCategorySpend,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Text('Recent activity',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < recent.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 140 + 35 * i),
                  child: TransactionTile(
                    transaction: recent[i],
                    category: categoriesById[recent[i].categoryId],
                    onTap: () {},
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load dashboard: $error')),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.spentMinor, required this.receivedMinor});

  final int spentMinor;
  final int receivedMinor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spent this month',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                AnimatedAmount(
                  amountMinor: spentMinor,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Received this month',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                AnimatedAmount(
                  amountMinor: receivedMinor,
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amountMinor,
    required this.fraction,
  });

  final Category? category;
  final int amountMinor;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(amountMinor / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconForKey(category?.icon), size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(category?.name ?? 'Uncategorized',
                  style: theme.textTheme.bodyMedium),
            ),
            Text(amount, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
