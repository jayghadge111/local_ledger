import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/db/providers.dart';
import '../../shared/widgets/category_icons.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? <Category>[];
    final budgets = ref.watch(budgetsProvider).value ?? <Budget>[];
    final transactions = ref.watch(transactionsProvider).value ?? <Transaction>[];

    final budgetByCategory = {for (final b in budgets) b.categoryId: b};

    final now = DateTime.now();
    final spendByCategory = <String, int>{};
    for (final t in transactions) {
      if (t.type != 'debit') continue;
      if (t.date.year != now.year || t.date.month != now.month) continue;
      spendByCategory.update(
        t.categoryId ?? 'cat_other',
        (v) => v + t.amountMinor,
        ifAbsent: () => t.amountMinor,
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Budgets')),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final category = categories[i];
            final budget = budgetByCategory[category.id];
            final spent = spendByCategory[category.id] ?? 0;
            return FadeSlideIn(
              delay: Duration(milliseconds: 20 * i),
              child: _BudgetRow(
                category: category,
                budget: budget,
                spentMinor: spent,
                onTap: () => _showEditDialog(context, ref, category, budget),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Budget? existing,
  ) async {
    final controller = TextEditingController(
      text: existing == null ? '' : (existing.monthlyLimitMinor / 100).toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${category.name} budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: const InputDecoration(
            labelText: 'Monthly limit (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              await ref.read(budgetsRepositoryProvider).setBudget(
                    categoryId: category.id,
                    monthlyLimitMinor: value * 100,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.budget,
    required this.spentMinor,
    required this.onTap,
  });

  final Category category;
  final Budget? budget;
  final int spentMinor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final hasBudget = budget != null;
    final fraction = hasBudget
        ? (spentMinor / budget!.monthlyLimitMinor).clamp(0.0, 1.5)
        : 0.0;
    final over = hasBudget && spentMinor > budget!.monthlyLimitMinor;
    final barColor = !hasBudget
        ? theme.colorScheme.outline
        : over
            ? theme.colorScheme.error
            : fraction > 0.8
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary;

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(iconForKey(category.icon), color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hasBudget ? fraction.clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasBudget
                      ? '${formatter.format(spentMinor / 100)} of ${formatter.format(budget!.monthlyLimitMinor / 100)}'
                      : '${formatter.format(spentMinor / 100)} spent · no budget set',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
