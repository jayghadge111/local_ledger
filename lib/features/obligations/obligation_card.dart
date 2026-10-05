import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/obligations/obligation_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_surface.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// "Today", "Tomorrow", "In 5 days", "2 days ago".
String dueLabel(DateTime due, DateTime now) {
  final days = DateTime(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days > 1) return 'In $days days';
  if (days == -1) return 'Yesterday';
  return '${-days} days ago';
}

IconData obligationIcon(Obligation o) {
  if (o.status == ObligationStatus.failed) return Icons.error_outline_rounded;
  return switch (o.kind) {
    'card_due' => Icons.credit_card_rounded,
    'emi_due' => Icons.account_balance_rounded,
    'mandate' => Icons.autorenew_rounded,
    _ => Icons.event_repeat_rounded,
  };
}

String obligationTitle(Obligation o) =>
    o.biller ??
    switch (o.kind) {
      'card_due' => 'Credit card bill',
      'emi_due' => 'Loan EMI',
      'mandate' => 'Auto-pay mandate',
      _ => 'Auto-debit',
    };

/// The small print under the title: what it is and which account.
String obligationDetail(Obligation o) {
  final parts = <String>[
    switch (o.kind) {
      'card_due' => 'Card bill',
      'emi_due' => 'EMI',
      'mandate' => 'Mandate',
      'bounce' => 'Failed debit',
      _ => 'Auto-debit',
    },
    if (o.refType == 'card' && o.refLast4 != null) 'Card ••${o.refLast4}',
    if (o.refType == 'loan' && o.refLast4 != null) 'Loan ${o.refLast4}',
    if (o.accountLast4 != null) 'A/c ••${o.accountLast4}',
    if (o.kind == 'card_due' && o.minDueMinor != null)
      'min ${_money.format(o.minDueMinor! / 100)}',
    if (o.kind == 'mandate' && o.frequency != null) o.frequency!,
    if (o.status == ObligationStatus.failed && o.reason != null) o.reason!,
  ];
  return parts.join(' · ');
}

/// One auto-debit, due, mandate or failure, as a compact row.
class ObligationCard extends StatelessWidget {
  const ObligationCard({super.key, required this.obligation, this.onTap});

  final Obligation obligation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = ChartColors.of(context);
    final o = obligation;
    final failed = o.status == ObligationStatus.failed;
    final now = DateTime.now();

    final amount = o.amountMinor == null
        ? null
        : '${o.kind == 'mandate' && o.isMaxAmount ? 'up to ' : ''}'
              '${_money.format(o.amountMinor! / 100)}';

    final (chipText, chipColor) = switch (o.status) {
      ObligationStatus.paid => ('Paid', Colors.green),
      ObligationStatus.failed => ('Failed', theme.colorScheme.error),
      ObligationStatus.missed => (
        'No payment seen',
        theme.colorScheme.onSurfaceVariant,
      ),
      ObligationStatus.active => ('Active', Colors.green),
      _ =>
        o.dueDate == null
            ? ('', theme.colorScheme.onSurfaceVariant)
            : (
                dueLabel(o.dueDate!, now),
                o.dueDate!.difference(now).inHours < 24
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
    };

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: failed
                ? theme.colorScheme.error.withValues(alpha: 0.14)
                : chart.soft,
            child: Icon(
              obligationIcon(o),
              size: 20,
              color: failed ? theme.colorScheme.error : chart.softText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obligationTitle(o),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  obligationDetail(o),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: failed
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (amount != null)
                Text(
                  amount,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (chipText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: chipColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
