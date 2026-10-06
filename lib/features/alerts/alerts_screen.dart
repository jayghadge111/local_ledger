import '../../core/money_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/analytics/budget_status.dart';
import '../../core/db/app_database.dart';
import '../../core/diagnostics/app_guard.dart';
import '../../core/db/budgets_repository.dart';
import '../../core/db/providers.dart';
import '../../core/lending/lending_math.dart';
import '../../core/lending/lending_repository.dart';
import '../../core/intelligence/intelligence_providers.dart';
import '../../core/intelligence/recurring_detector.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/permissions/app_permissions.dart';
import '../../core/obligations/obligation_repository.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/permission_notice.dart';
import '../../shared/widgets/placeholder_body.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/widgets/home_budgets_card.dart';
import '../lending/lending_screen.dart';
import '../obligations/obligation_card.dart';
import '../obligations/obligations_screen.dart';
import '../transactions/widgets/transaction_tile.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncReminders();
  }

  Future<void> _syncReminders() =>
      guarded('alert reminders', _scheduleReminders);

  Future<void> _scheduleReminders() async {
    final insights = ref.read(recurringInsightsProvider);
    if (insights.isEmpty) return;
    final notifications = ref.read(notificationServiceProvider);
    await notifications.init();
    for (final insight in insights) {
      final id = insight.merchant.toLowerCase().trim().hashCode & 0x7fffffff;
      await notifications.scheduleRecurringReminder(
        id: id,
        merchant: insight.merchant,
        dueDate: insight.nextExpectedDate,
        amountLabel: appCurrency(symbol: '₹',
          decimalDigits: 0,
        ).format(insight.expectedAmountMinor / 100),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recurring = ref.watch(recurringInsightsProvider);
    final unusual = ref.watch(unusualTransactionsProvider);
    final international = ref.watch(internationalTransactionsProvider);
    final categoriesById = {
      for (final c in ref.watch(categoriesProvider).value ?? []) c.id: c,
    };

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final budgetAlerts = budgetStatuses(
      budgets: ref.watch(monthBudgetsProvider(month)),
      transactions: ref.watch(analyticsTransactionsProvider),
      month: month,
    ).where((s) => s.level != BudgetLevel.ok).toList();
    final categoryNames = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final lendingDue = dueSoon(ref.watch(lendingBalancesProvider), now);
    final failedDebits = ref.watch(recentFailuresProvider);
    final upcomingDebits = ref.watch(upcomingObligationsProvider);
    final notificationState = ref.watch(
      permissionsProvider,
    )[AppPermission.notifications];

    if (failedDebits.isEmpty &&
        upcomingDebits.isEmpty &&
        recurring.isEmpty &&
        unusual.isEmpty &&
        international.isEmpty &&
        budgetAlerts.isEmpty &&
        lendingDue.isEmpty) {
      return const PlaceholderBody(
        icon: Icons.notifications_outlined,
        title: 'All quiet',
        subtitle: 'Recurring-payment reminders and unusual or international transaction flags will show up here as your transaction history grows.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (notificationState == PermissionState.denied ||
            notificationState == PermissionState.blocked) ...[
          PermissionNotice(
            state: notificationState!,
            message: 'Notifications are off, so reminders only show here, not as phone alerts.',
            onAllow: () => ref
                .read(permissionsProvider.notifier)
                .request(AppPermission.notifications),
            onOpenSettings: () =>
                ref.read(permissionsProvider.notifier).openSettings(),
          ),
          const SizedBox(height: 12),
        ],
        if (failedDebits.isNotEmpty) ...[
          Text(
            'Auto-debit failed',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Add money to your account to avoid return charges.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final o in failedDebits.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ObligationCard(
                obligation: o,
                onTap: () => showObligationDetails(context, ref, o),
              ),
            ),
          const SizedBox(height: 10),
        ],
        if (upcomingDebits.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Upcoming auto-debits & dues',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ObligationsScreen()),
                ),
                child: Text(
                  upcomingDebits.length > 3
                      ? 'See all ${upcomingDebits.length}'
                      : 'Open',
                ),
              ),
            ],
          ),
          Text(
            'Not counted as spending until the money leaves.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final o in upcomingDebits.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ObligationCard(
                obligation: o,
                onTap: () => showObligationDetails(context, ref, o),
              ),
            ),
          const SizedBox(height: 10),
        ],
        if (budgetAlerts.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget alerts',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                ),
                child: const Text('Manage budgets'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GlassCard(
            child: Column(
              children: [
                for (final s in budgetAlerts) ...[
                  BudgetLine(status: s, category: categoryNames[s.categoryId]),
                  if (s != budgetAlerts.last) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (lendingDue.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lend & borrow reminders',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LendingScreen()),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final b in lendingDue)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LendingCard(balance: b),
            ),
          const SizedBox(height: 8),
        ],
        if (recurring.isNotEmpty) ...[
          Text(
            'Upcoming recurring payments',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < recurring.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 30 * i),
                child: _RecurringCard(insight: recurring[i]),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (unusual.isNotEmpty) ...[
          Text('Unusual transactions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (var i = 0; i < unusual.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 30 * i),
                child: TransactionTile(
                  transaction: unusual[i],
                  category: categoriesById[unusual[i].categoryId],
                  onTap: () {},
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (international.isNotEmpty) ...[
          Text(
            'International transactions',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < international.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 30 * i),
                child: TransactionTile(
                  transaction: international[i],
                  category: categoriesById[international[i].categoryId],
                  onTap: () {},
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({required this.insight});

  final RecurringInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysUntil = insight.daysUntilDue;
    final dueLabel = daysUntil < 0
        ? '${-daysUntil}d overdue'
        : daysUntil == 0
        ? 'Due today'
        : 'Due in ${daysUntil}d';
    final amount = appCurrency(symbol: '₹',
      decimalDigits: 0,
    ).format(insight.expectedAmountMinor / 100);

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              Icons.autorenew,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.merchant, style: theme.textTheme.titleMedium),
                Text(
                  '~every ${insight.intervalDays} days · $amount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  (daysUntil < 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.secondary)
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              dueLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: daysUntil < 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
