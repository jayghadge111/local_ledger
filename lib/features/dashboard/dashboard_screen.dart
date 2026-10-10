import '../../shared/widgets/shimmer.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../shared/widgets/animated_amount.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/greeting_header.dart';
import '../../shared/widgets/placeholder_body.dart';
import '../update/update_banner.dart';
import 'dashboard_month.dart';
import 'dashboard_summary.dart';
import 'expense_detail_screen.dart';
import 'widgets/home_budgets_card.dart';
import 'widgets/month_selector.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/spend_bar_chart.dart';
import 'widgets/budget_review_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final analytics = ref.watch(analyticsTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final month = ref.watch(dashboardMonthProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    GreetingHeader(),
                    SizedBox(height: 12),
                    UpdateBanner(),
                  ],
                ),
              ),
              Expanded(
                child: PlaceholderBody(
                  icon: Icons.grid_view_rounded,
                  title: 'Welcome to TrueLedger',
                  subtitle: 'Add a transaction (or load sample data from Settings) to see your dashboard come alive.',
                ),
              ),
            ],
          );
        }

        final summary = ref.watch(dashboardSummaryProvider(month));
        final spent = summary.spentMinor;
        final received = summary.receivedMinor;
        final categorySlices = summary.slices;
        final buckets = summary.buckets;
        final hasTrendData = summary.hasTrendData;
        final categoriesById = {
          for (final c in categoriesAsync.value ?? <Category>[]) c.id: c,
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            const FadeSlideIn(child: GreetingHeader()),
            const SizedBox(height: 12),
            const UpdateBanner(),
            const SizedBox(height: 4),
            const FadeSlideIn(
              delay: Duration(milliseconds: 10),
              child: MonthSelector(),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 20),
              child: _SummaryRow(
                spentMinor: spent,
                receivedMinor: received,
                month: month,
              ),
            ),
            const SizedBox(height: 16),
            const BudgetReviewCard(),
            if (hasTrendData)
              FadeSlideIn(
                delay: const Duration(milliseconds: 45),
                child: GlassCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpenseDetailScreen(
                        transactions: analytics,
                        categoriesById: categoriesById,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Spend trend',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SpendBarChart(buckets: buckets, barsHeight: 120),
                    ],
                  ),
                ),
              ),
            if (hasTrendData) const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentMonth(month)
                          ? 'This month by category'
                          : '${monthYearLabel(month)} by category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (categorySlices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No spending in ${monthYearLabel(month)}.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    else
                      CategoryDonutChart(
                        slices: categorySlices,
                        totalMinor: spent,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const FadeSlideIn(
              delay: Duration(milliseconds: 80),
              child: HomeBudgetsCard(),
            ),
          ],
        );
      },
      loading: () => const HomeSkeleton(),
      error: (error, _) =>
          Center(child: Text('Could not load dashboard: $error')),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.spentMinor,
    required this.receivedMinor,
    required this.month,
  });

  final int spentMinor;
  final int receivedMinor;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: _SummaryTile(
              icon: Icons.arrow_upward_rounded,
              color: Colors.red,
              label: 'Spent ${monthPhrase(month)}',
              amountMinor: spentMinor,
              theme: theme,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: _SummaryTile(
              icon: Icons.arrow_downward_rounded,
              color: Colors.green,
              label: 'Received ${monthPhrase(month)}',
              amountMinor: receivedMinor,
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.amountMinor,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int amountMinor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedAmount(
          amountMinor: amountMinor,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
