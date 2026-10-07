import '../../core/money_format.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/db/app_database.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/db/providers.dart';
import '../../core/ui/undo.dart';
import '../../shared/widgets/text_button_styles.dart';
import '../../shared/widgets/category_icons.dart';
import '../../shared/widgets/centered_dialog_card.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../dashboard/dashboard_month.dart';
import '../dashboard/widgets/month_selector.dart';

/// Monthly limits per category. A limit can start in a month and carry on
/// from there, or apply to just one month (say, a tighter October). Months
/// that are over are locked: they keep the budget they had, and changing one
/// takes a deliberate "Edit anyway" and affects only that month.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? <Category>[];
    final month = ref.watch(dashboardMonthProvider);
    final budgets = ref.watch(monthBudgetsProvider(month));
    final overrides =
        ref.watch(budgetOverridesProvider).value ?? const <BudgetOverride>[];
    final transactions = ref.watch(analyticsTransactionsProvider);
    final past = isPastMonth(month, DateTime.now());

    final budgetByCategory = {for (final b in budgets) b.categoryId: b};
    final key = monthKeyOf(month);
    final customThisMonth = {
      for (final o in overrides)
        if (o.monthKey == key) o.categoryId,
    };
    // A limit of 0 for the month is "no budget this month", not a custom
    // limit, so it gets no "Oct only" badge.
    final badgedThisMonth = {
      for (final o in overrides)
        if (o.monthKey == key && o.limitMinor > 0) o.categoryId,
    };

    final spendByCategory = <String, int>{};
    for (final t in transactions) {
      if (t.type != 'debit') continue;
      if (t.date.year != month.year || t.date.month != month.month) continue;
      spendByCategory.update(
        t.categoryId ?? 'cat_other',
        (v) => v + t.amountMinor,
        ifAbsent: () => t.amountMinor,
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text('Budgets · ${monthYearLabel(month)}')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            const MonthSelector(),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                past
                    ? '${monthYearLabel(month)} is over, so its budgets are locked. Tap a category to change one for this month only.'
                    : 'Tap a category to set its limit — from ${monthYearLabel(month)} on, or only for ${monthYearLabel(month)}.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (var i = 0; i < categories.length; i++) ...[
              FadeSlideIn(
                delay: Duration(milliseconds: 20 * i.clamp(0, 12)),
                child: _BudgetRow(
                  category: categories[i],
                  budget: budgetByCategory[categories[i].id],
                  spentMinor: spendByCategory[categories[i].id] ?? 0,
                  customForMonth: badgedThisMonth.contains(categories[i].id),
                  month: month,
                  locked: past,
                  onRemove: budgetByCategory[categories[i].id] == null
                      ? null
                      : () =>
                            _confirmRemove(context, ref, categories[i], month),
                  onTap: () async {
                    if (past && !await _confirmEditPast(context, month)) return;
                    if (!context.mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (_) => CenteredDialogCard(
                        child: _BudgetDialog(
                          category: categories[i],
                          month: month,
                          pastMonth: past,
                          current: budgetByCategory[categories[i].id],
                          customForMonth: customThisMonth.contains(
                            categories[i].id,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// Takes a budget away for [month] only, after asking, with an undo. Other
/// months keep theirs.
Future<void> _confirmRemove(
  BuildContext context,
  WidgetRef ref,
  Category category,
  DateTime month,
) async {
  final name = DateFormat('MMMM yyyy').format(month);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove ${category.name} budget?'),
      content: Text(
        'This removes it for $name only. Other months keep theirs.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: dangerTextButtonStyle(context),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final undo = await ref
      .read(budgetsRepositoryProvider)
      .removeBudget(categoryId: category.id, month: month, fromHere: false);
  showUndoSnackBar('${category.name} budget removed', undo);
}

/// Asks before touching a month that is over.
Future<bool> _confirmEditPast(BuildContext context, DateTime month) async {
  final name = DateFormat('MMMM yyyy').format(month);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$name is over'),
      content: Text(
        'Its budgets are locked so past results stay accurate. You can still '
        'change one for $name only — other months are not affected.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Edit anyway'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

enum _Scope { thisMonth, fromHere }

class _BudgetDialog extends ConsumerStatefulWidget {
  const _BudgetDialog({
    required this.category,
    required this.month,
    required this.pastMonth,
    required this.current,
    required this.customForMonth,
  });

  final Category category;
  final DateTime month;

  /// The month is over: only "this month" is offered.
  final bool pastMonth;
  final Budget? current;
  final bool customForMonth;

  @override
  ConsumerState<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends ConsumerState<_BudgetDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : (widget.current!.monthlyLimitMinor / 100).toStringAsFixed(0),
  );

  // Changing an existing limit defaults to "just this month" so later months
  // aren't altered by accident; a first budget carries on from this month.
  // A month that is over can only be changed for itself.
  late _Scope _scope = widget.pastMonth || widget.current != null
      ? _Scope.thisMonth
      : _Scope.fromHere;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a whole-rupee amount');
      return;
    }
    final repo = ref.read(budgetsRepositoryProvider);
    if (_scope == _Scope.thisMonth) {
      await repo.setMonthBudget(
        categoryId: widget.category.id,
        month: widget.month,
        limitMinor: value * 100,
      );
    } else {
      await repo.setBudgetFrom(
        categoryId: widget.category.id,
        fromMonth: widget.month,
        limitMinor: value * 100,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final undo = await ref
        .read(budgetsRepositoryProvider)
        .removeBudget(
          categoryId: widget.category.id,
          month: widget.month,
          fromHere: !widget.pastMonth && _scope == _Scope.fromHere,
        );
    if (mounted) Navigator.of(context).pop();
    showUndoSnackBar('${widget.category.name} budget removed', undo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(widget.month);
    final repo = ref.read(budgetsRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.category.name} budget',
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monthly limit (₹)',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Apply to', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  if (widget.pastMonth)
                    Text(
                      'Only $monthName. It is over, so other months keep their limits.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else ...[
                    SegmentedButton<_Scope>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: _Scope.thisMonth,
                          label: Text(
                            'Only ${DateFormat('MMM').format(widget.month)}',
                          ),
                        ),
                        ButtonSegment(
                          value: _Scope.fromHere,
                          label: Text(
                            'From ${DateFormat('MMM').format(widget.month)} on',
                          ),
                        ),
                      ],
                      selected: {_scope},
                      onSelectionChanged: (s) =>
                          setState(() => _scope = s.first),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _scope == _Scope.thisMonth
                          ? 'Only $monthName changes; every other month keeps its own limit.'
                          : '$monthName and every month after it, until you change it again. Earlier months are not touched.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  if (widget.current != null)
                    TextButton.icon(
                      onPressed: _remove,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        widget.pastMonth || _scope == _Scope.thisMonth
                            ? 'Remove budget for $monthName'
                            : 'Remove budget from $monthName on',
                      ),
                      style: dangerTextButtonStyle(context),
                    ),
                  if (widget.customForMonth)
                    TextButton(
                      onPressed: () async {
                        await repo.clearMonthBudget(
                          categoryId: widget.category.id,
                          month: widget.month,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text('Use the usual limit for $monthName'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.budget,
    required this.spentMinor,
    required this.customForMonth,
    required this.month,
    required this.locked,
    required this.onTap,
    this.onRemove,
  });

  final Category category;
  final Budget? budget;
  final int spentMinor;
  final bool customForMonth;
  final DateTime month;

  /// The month is over, so the budget is locked.
  final bool locked;
  final VoidCallback onTap;

  /// Takes the budget away; null when there is none to remove.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = appCurrency(symbol: '₹', decimalDigits: 0);
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (customForMonth) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${DateFormat('MMM').format(month)} only',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hasBudget ? fraction.clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasBudget
                      ? '${formatter.format(spentMinor / 100)} of ${formatter.format(budget!.monthlyLimitMinor / 100)}'
                      : '${formatter.format(spentMinor / 100)} spent · no budget set',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove ${category.name} budget',
              color: dangerColor(context),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onRemove,
            ),
          Icon(locked ? Icons.lock_outline_rounded : Icons.chevron_right),
        ],
      ),
    );
  }
}
