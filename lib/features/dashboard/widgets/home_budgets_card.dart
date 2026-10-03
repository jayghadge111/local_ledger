import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/analytics/budget_status.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/budgets_repository.dart';
import '../../../core/db/providers.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../budgets/budgets_screen.dart';
import '../dashboard_month.dart';

/// Budgets for the month on screen, right on Home: each budgeted category with
/// what's been spent against its limit, over-budget ones first and in red.
class HomeBudgetsCard extends ConsumerWidget {
  const HomeBudgetsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(dashboardMonthProvider);
    final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final statuses = budgetStatuses(
      budgets: budgets,
      transactions: ref.watch(analyticsTransactionsProvider),
      month: month,
    );
    final overCount = statuses.where((s) => s.isOver).length;
    void openBudgets() =>
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BudgetsScreen()));

    if (statuses.isEmpty) {
      return GlassCard(
        onTap: openBudgets,
        child: Row(
          children: [
            Icon(
              Icons.savings_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budgets', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Set a monthly limit per category and see here when you go over.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }

    final shown = statuses.take(5).toList();
    return GlassCard(
      onTap: openBudgets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budgets · ${DateFormat('MMM yyyy').format(month)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (overCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$overCount over budget',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final s in shown) ...[
            _BudgetLine(status: s, category: categories[s.categoryId]),
            if (s != shown.last) const SizedBox(height: 14),
          ],
          if (statuses.length > shown.length) ...[
            const SizedBox(height: 10),
            Text(
              '+${statuses.length - shown.length} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.status, required this.category});

  final BudgetStatus status;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final color = switch (status.level) {
      BudgetLevel.over => theme.colorScheme.error,
      BudgetLevel.warning => const Color(0xFFE08A00),
      BudgetLevel.ok => theme.colorScheme.onSurface,
    };
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconForKey(category?.icon), size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category?.name ?? 'Other',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${money.format(status.spentMinor / 100)} / ${money.format(status.limitMinor / 100)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: status.fraction.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.6),
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status.isOver
              ? '${money.format(status.overByMinor / 100)} over the limit'
              : '${money.format(status.remainingMinor / 100)} left · ${(status.fraction * 100).round()}% used',
          style: theme.textTheme.labelSmall?.copyWith(
            color: status.isOver ? color : muted,
            fontWeight: status.isOver ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}
