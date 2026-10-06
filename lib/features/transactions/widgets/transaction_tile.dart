import '../../../core/money_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/small_repositories.dart';
import '../../splits/split_summary.dart';
import '../transaction_title.dart';
import '../../../shared/widgets/flag_chip.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/merchant_avatar.dart';

class TransactionTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final account = ref.watch(accountsByIdProvider)[transaction.accountId];
    final cardLabel = _cardChipLabel(account);
    final shares =
        ref.watch(splitsByTxnProvider)[transaction.id] ?? const <SplitShare>[];
    final hasSplit = shares.isNotEmpty && transaction.type == 'debit';
    final isCredit = transaction.type == 'credit';
    final isTransfer = transaction.kind == 'transfer';
    final isRefund = transaction.kind == 'refund';
    final isCardPayment = transaction.kind == 'card_payment';
    final isInr = transaction.currency == 'INR';
    final amount = appCurrency(symbol: isInr ? '₹' : '${transaction.currency} ',
      decimalDigits: 2,
    ).format(transaction.amountMinor / 100);
    // Transfers aren't income or spending, so they stay neutral.
    final amountColor = (isTransfer || isCardPayment)
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
            isTransfer: isTransfer,
            bankName: transaction.rawMerchant == null
                ? account?.bankName
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transactionTitle(transaction),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${isTransfer || isCardPayment ? 'Not counted' : (category?.name ?? 'Uncategorized')} · ${DateFormat.yMMMd().format(transaction.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (cardLabel != null ||
                    hasSplit ||
                    transaction.isInternational ||
                    transaction.isFlaggedUnusual ||
                    isRefund ||
                    isCardPayment) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (hasSplit)
                        FlagChip(
                          icon: Icons.call_split_rounded,
                          label: splitChipLabel(shares),
                          color: theme.colorScheme.onSurface,
                        ),
                      if (cardLabel != null)
                        FlagChip(
                          icon: account!.accountType == 'forex'
                              ? Icons.currency_exchange_rounded
                              : Icons.credit_card_rounded,
                          label: cardLabel,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (isCardPayment)
                        FlagChip(
                          icon: Icons.credit_score_rounded,
                          label: 'Card bill · not counted',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (isRefund)
                        FlagChip(
                          icon: Icons.undo_rounded,
                          label: 'Refund',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (transaction.isInternational)
                        FlagChip(
                          icon: Icons.public,
                          label: 'International',
                          color: theme.colorScheme.tertiary,
                        ),
                      if (transaction.isFlaggedUnusual)
                        FlagChip(
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
          // The amount may take a share of the row, never all of it: with big
          // system text it scales down instead of pushing the row wider.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.42,
            ),
            child: Column(
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    isCredit ? '+$amount' : '-$amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasSplit)
                  Text(
                    'Your share ${appCurrency(symbol: isInr ? '₹' : '${transaction.currency} ', decimalDigits: 2).format(myShareMinor(transaction.amountMinor, shares) / 100)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// e.g. "Forex card ••1233" — shown for cards only, since a chip on every
/// bank-account transaction would be noise.
String? _cardChipLabel(Account? account) {
  if (account == null) return null;
  final kind = switch (account.accountType) {
    'forex' => 'Forex card',
    'prepaid' => 'Prepaid card',
    'credit_card' => 'Credit card',
    'debit_card' => 'Debit card',
    'card' => 'Card',
    _ => null,
  };
  if (kind == null) return null;
  return account.last4 == null ? kind : '$kind ••${account.last4}';
}
