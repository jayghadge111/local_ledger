import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/merchant_avatar.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.onTap,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.type == 'credit';
    final isTransfer = transaction.kind == 'transfer';
    final isRefund = transaction.kind == 'refund';
    final isInr = transaction.currency == 'INR';
    final amount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: isInr ? '₹' : '${transaction.currency} ',
      decimalDigits: 2,
    ).format(transaction.amountMinor / 100);
    // Transfers aren't income or spending, so they stay neutral.
    final amountColor = isTransfer
        ? theme.colorScheme.onSurfaceVariant
        : (isCredit ? Colors.green : Colors.red);

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          MerchantAvatar(
            merchant: transaction.merchant,
            categoryIconKey: category?.icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.merchant, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${category?.name ?? 'Uncategorized'} · ${DateFormat.yMMMd().format(transaction.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (transaction.isInternational ||
                    transaction.isFlaggedUnusual ||
                    isTransfer ||
                    isRefund) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (isTransfer)
                        _FlagChip(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Transfer',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (isRefund)
                        _FlagChip(
                          icon: Icons.undo_rounded,
                          label: 'Refund',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (transaction.isInternational)
                        _FlagChip(
                          icon: Icons.public,
                          label: 'International',
                          color: theme.colorScheme.tertiary,
                        ),
                      if (transaction.isFlaggedUnusual)
                        _FlagChip(
                          icon: Icons.warning_amber_rounded,
                          label: 'Unusual',
                          color: theme.colorScheme.error,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 14,
                color: amountColor,
              ),
              const SizedBox(height: 2),
              Text(
                isCredit ? '+$amount' : '-$amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
