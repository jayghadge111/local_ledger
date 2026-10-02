import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/providers.dart';
import '../../core/intelligence/intelligence_providers.dart';
import '../../core/intelligence/recurring_detector.dart';
import '../../core/notifications/notification_providers.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/placeholder_body.dart';
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

  Future<void> _syncReminders() async {
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
        amountLabel: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format(insight.expectedAmountMinor / 100),
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
      for (final c in ref.watch(categoriesProvider).value ?? [])
        c.id: c,
    };

    if (recurring.isEmpty && unusual.isEmpty && international.isEmpty) {
      return const PlaceholderBody(
        icon: Icons.notifications_outlined,
        title: 'All quiet',
        subtitle:
            'Recurring-payment reminders and unusual or international transaction flags will show up here as your transaction history grows.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (recurring.isNotEmpty) ...[
          Text('Upcoming recurring payments', style: theme.textTheme.titleMedium),
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
          Text('International transactions', style: theme.textTheme.titleMedium),
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
    final amount = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(insight.expectedAmountMinor / 100);

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(Icons.autorenew, color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.merchant, style: theme.textTheme.titleMedium),
                Text(
                  '~every ${insight.intervalDays} days · $amount',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (daysUntil < 0 ? theme.colorScheme.error : theme.colorScheme.secondary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              dueLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: daysUntil < 0 ? theme.colorScheme.error : theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
