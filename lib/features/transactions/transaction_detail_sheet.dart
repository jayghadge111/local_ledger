import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/small_repositories.dart';
import '../../core/security/encryption_providers.dart';
import '../../shared/widgets/centered_dialog_card.dart';
import '../../shared/widgets/flag_chip.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/merchant_avatar.dart';
import '../splits/split_summary.dart';
import '../splits/splits_ui.dart';
import 'transaction_form_sheet.dart';
import 'transaction_title.dart';

/// Opens the read-only details of [transaction]: everything known about it,
/// including who a split is shared with. "Edit" leads on to the form.
Future<void> showTransactionDetail(
  BuildContext context,
  Transaction transaction,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => CenteredDialogCard(
      child: TransactionDetailSheet(
        transaction: transaction,
        hostContext: context,
      ),
    ),
  );
}

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.hostContext,
  });

  final Transaction transaction;

  /// The screen underneath the dialog — used to open the edit form after
  /// this dialog closes.
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Watch the live row so edits (e.g. a split just added) show immediately.
    final all = ref.watch(transactionsProvider).value ?? const <Transaction>[];
    final t =
        all.where((x) => x.id == transaction.id).firstOrNull ?? transaction;
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        c.id: c,
    };
    final account = ref.watch(accountsByIdProvider)[t.accountId];
    final shares = ref.watch(splitsByTxnProvider)[t.id] ?? const <SplitShare>[];

    final isCredit = t.type == 'credit';
    final isTransfer = t.kind == 'transfer';
    final isInr = t.currency == 'INR';
    final money = NumberFormat.currency(
      locale: 'en_IN',
      symbol: isInr ? '₹' : '${t.currency} ',
      decimalDigits: 2,
    );
    final amountColor = isTransfer
        ? theme.colorScheme.onSurfaceVariant
        : (isCredit ? Colors.green : Colors.red);

    final refundedBy = all
        .where(
          (x) => x.kind == 'refund' && x.refundOfId == t.id && !x.isDeleted,
        )
        .toList();
    final refundOf = t.refundOfId == null
        ? null
        : all.where((x) => x.id == t.refundOfId).firstOrNull;
    final category = categories[t.categoryId];

    final rows = <(String, String)>[
      ('Date', DateFormat.yMMMd().add_jm().format(t.date)),
      ('Type', isCredit ? 'Received' : 'Spent'),
      if (category != null) ('Category', category.name),
      if (account != null) ('Account', account.name),
      (
        'Source',
        switch (t.source) {
          'sms' => 'Bank SMS',
          'email' => 'Bank email',
          _ => 'Added manually',
        },
      ),
      if (isTransfer)
        (isCredit ? 'Received from' : 'Sent to', t.rawMerchant ?? t.merchant),
      if (!isTransfer &&
          t.rawMerchant != null &&
          t.rawMerchant!.toLowerCase() != t.merchant.toLowerCase())
        ('Shown by bank as', t.rawMerchant!),
      if (!isInr) ('Currency', t.currency),
      if (refundOf != null)
        (
          'Refund of',
          '${refundOf.merchant} · ${DateFormat.MMMd().format(refundOf.date)} · ${money.format(refundOf.amountMinor / 100)}',
        ),
      for (final r in refundedBy)
        (
          'Refunded',
          '${money.format(r.amountMinor / 100)} on ${DateFormat.MMMd().format(r.date)}',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
                      MerchantAvatar(
                        merchant: t.merchant,
                        categoryIconKey: category?.icon,
                        isTransfer: isTransfer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          transactionTitle(t),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${isCredit ? '+' : '-'}${money.format(t.amountMinor / 100)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (shares.isNotEmpty && !isCredit)
                    Text(
                      'Your share ${money.format(myShareMinor(t.amountMinor, shares) / 100)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (isTransfer)
                        FlagChip(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Not counted in totals',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (t.kind == 'refund')
                        FlagChip(
                          icon: Icons.undo_rounded,
                          label: 'Refund',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (t.isInternational)
                        FlagChip(
                          icon: Icons.public,
                          label: 'International',
                          color: theme.colorScheme.tertiary,
                        ),
                      if (t.isFlaggedUnusual)
                        FlagChip(
                          icon: Icons.warning_amber_rounded,
                          label: 'Unusual',
                          color: theme.colorScheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final (label, value) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 118,
                            child: Text(label, style: muted),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isCredit) ...[
                    const Divider(height: 28),
                    _SplitSection(transaction: t, shares: shares, money: money),
                  ],
                  if (t.rawTextEncrypted != null)
                    _OriginalMessage(encrypted: t.rawTextEncrypted!),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showTransactionFormSheet(hostContext, existing: t);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit transaction'),
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

class _SplitSection extends ConsumerWidget {
  const _SplitSection({
    required this.transaction,
    required this.shares,
    required this.money,
  });

  final Transaction transaction;
  final List<SplitShare> shares;
  final NumberFormat money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (shares.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => showSplitSheet(context, transaction),
          icon: const Icon(Icons.call_split_rounded),
          label: const Text('Split with others'),
        ),
      );
    }

    final owed = shares
        .where((s) => !s.settled)
        .fold<int>(0, (sum, s) => sum + s.shareMinor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.call_split_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Split with', style: theme.textTheme.titleMedium),
            ),
            Text(
              owed == 0
                  ? 'All settled'
                  : '${money.format(owed / 100)} to get back',
              style: muted,
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final s in shares)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: s.settled,
            onChanged: (v) =>
                ref.read(splitsRepositoryProvider).setSettled(s.id, v ?? false),
            title: Text(s.personName),
            subtitle: Text(s.settled ? 'Paid back' : 'Owes you', style: muted),
            secondary: Text(
              money.format(s.shareMinor / 100),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showSplitSheet(context, transaction),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit split'),
          ),
        ),
      ],
    );
  }
}

/// The original bank SMS/email, decrypted only when expanded.
class _OriginalMessage extends ConsumerWidget {
  const _OriginalMessage({required this.encrypted});
  final String encrypted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text('Original message', style: theme.textTheme.titleSmall),
        children: [
          FutureBuilder<String>(
            future: ref
                .read(encryptionServiceProvider)
                .decryptString(encrypted),
            builder: (context, snapshot) => Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                snapshot.data ??
                    (snapshot.hasError ? 'Could not be read.' : '…'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
