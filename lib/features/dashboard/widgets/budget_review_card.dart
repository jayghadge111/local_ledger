import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/budget_review.dart';
import '../../../core/analytics/budget_review_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/budgets_repository.dart';
import '../../../core/db/providers.dart';
import '../../../core/db/settings_repository.dart';
import '../../../core/ui/root_messenger.dart';
import '../../../shared/widgets/category_icons.dart';
import '../../../shared/widgets/centered_dialog_card.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../budgets/budgets_screen.dart';
import '../dashboard_month.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// At the start of a month: "September: 3 budgets went over — raise them for
/// October, or keep them?" One tap raises a limit to a figure that would have
/// covered last month. Hidden after the first days of the month, once every
/// suggestion is handled, or when put away.
class BudgetReviewCard extends ConsumerWidget {
  const BudgetReviewCard({super.key, this.today = _systemToday});

  /// What counts as today (replaceable in tests).
  final DateTime Function() today;
  static DateTime _systemToday() => DateTime.now();

  static const _maxRows = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(dashboardMonthProvider);
    if (!isCurrentMonth(shown)) return const SizedBox.shrink();

    final now = today();
    final thisMonth = DateTime(now.year, now.month);
    final thisKey = monthKeyOf(thisMonth);
    final review = ref.watch(budgetReviewProvider);
    final dismissed = ref.watch(budgetReviewDismissedProvider).value;
    if (!shouldShowReview(
      review: review,
      now: now,
      dismissedForMonthKey: dismissed,
      currentMonthKey: thisKey,
    )) {
      return const SizedBox.shrink();
    }

    final pending = _pendingItems(ref, review!, thisMonth);
    if (pending.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final lastName = DateFormat('MMMM').format(review.month);
    final thisName = DateFormat('MMMM').format(thisMonth);
    final shownRows = pending.take(_maxRows).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$lastName review',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${review.overCount} of ${review.totalBudgets} went over'
                        ' · raise for $thisName?',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final item in shownRows)
              _Row(
                item: item,
                category: categories[item.categoryId],
                onRaise: () => _raise(
                  ref,
                  item,
                  categories[item.categoryId]?.name,
                  thisMonth,
                ),
              ),
            Row(
              children: [
                if (pending.length > shownRows.length)
                  TextButton(
                    style: _compactButton,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => CenteredDialogCard(
                        child: _AllReviewDialog(today: today),
                      ),
                    ),
                    child: Text(
                      'Show ${pending.length - shownRows.length} more',
                    ),
                  ),
                const Spacer(),
                TextButton(
                  style: _compactButton,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                  ),
                  child: const Text('Review budgets'),
                ),
                TextButton(
                  style: _compactButton,
                  onPressed: () => ref
                      .read(settingsRepositoryProvider)
                      .set(SettingsKeys.budgetReviewDismissed, thisKey),
                  child: const Text('Keep as is'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small text buttons, so the card stays short.
final _compactButton = TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  minimumSize: const Size(0, 30),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
);

/// What is still worth offering: anything already raised to (or past) the
/// suggestion is skipped.
List<ReviewItem> _pendingItems(
  WidgetRef ref,
  BudgetReview review,
  DateTime thisMonth,
) {
  final limitNow = {
    for (final b in ref.watch(monthBudgetsProvider(thisMonth)))
      b.categoryId: b.monthlyLimitMinor,
  };
  return [
    for (final i in review.over)
      if ((limitNow[i.categoryId] ?? 0) < i.suggestedMinor) i,
  ];
}

Future<void> _raise(
  WidgetRef ref,
  ReviewItem item,
  String? categoryName,
  DateTime thisMonth,
) async {
  await ref
      .read(budgetsRepositoryProvider)
      .setBudgetFrom(
        categoryId: item.categoryId,
        fromMonth: thisMonth,
        limitMinor: item.suggestedMinor,
      );
  showRootSnackBar(
    '${categoryName ?? 'Budget'} is now '
    '${_money.format(item.suggestedMinor / 100)} from '
    '${DateFormat('MMMM').format(thisMonth)}',
  );
}

/// Every suggestion in one place, for when there are more than the card shows.
class _AllReviewDialog extends ConsumerWidget {
  const _AllReviewDialog({required this.today});

  final DateTime Function() today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = today();
    final thisMonth = DateTime(now.year, now.month);
    final review = ref.watch(budgetReviewProvider);
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final pending = review == null
        ? const <ReviewItem>[]
        : _pendingItems(ref, review, thisMonth);

    // Nothing left to decide: close.
    if (pending.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review == null
                            ? 'Budget review'
                            : '${DateFormat('MMMM').format(review.month)} review',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Text(
                    'Raise a limit for ${DateFormat('MMMM').format(thisMonth)} '
                    'in one tap.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final item in pending)
                          _Row(
                            item: item,
                            category: categories[item.categoryId],
                            onRaise: () => _raise(
                              ref,
                              item,
                              categories[item.categoryId]?.name,
                              thisMonth,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.category,
    required this.onRaise,
  });

  final ReviewItem item;
  final Category? category;
  final VoidCallback onRaise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            iconForKey(category?.icon),
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Other',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_money.format(item.spentMinor / 100)} / '
                  '${_money.format(item.limitMinor / 100)} · '
                  '${(item.fraction * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: _compactButton,
            onPressed: onRaise,
            child: Text('Raise to ${_money.format(item.suggestedMinor / 100)}'),
          ),
        ],
      ),
    );
  }
}
