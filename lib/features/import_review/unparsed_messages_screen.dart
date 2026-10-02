import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/small_repositories.dart';
import '../../core/sms/bank_sms_parser.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../transactions/transaction_form_sheet.dart';

/// Bank messages that quoted an amount but couldn't be read automatically.
/// The user either adds the transaction by hand (amount prefilled) or
/// dismisses the message.
class UnparsedMessagesScreen extends ConsumerWidget {
  const UnparsedMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messages = ref.watch(unparsedMessagesProvider).value ?? const <UnparsedMessage>[];
    final repo = ref.watch(unparsedRepositoryProvider);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Messages to review')),
        body: messages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Nothing to review — every bank message was understood.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final m = messages[i];
                  return GlassCard(
                    child: FutureBuilder<String>(
                      future: repo.readBody(m),
                      builder: (context, snapshot) {
                        final body = snapshot.data ?? '…';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.senderCode ?? m.source} · ${DateFormat.yMMMd().add_jm().format(m.receivedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 6),
                            Text(body, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: snapshot.hasData
                                      ? () async {
                                          final saved = await showTransactionFormSheet(
                                            context,
                                            prefill: TransactionPrefill(
                                              amountMinor: extractAmountMinor(body),
                                              date: m.receivedAt,
                                            ),
                                          );
                                          if (saved == true) await repo.resolve(m.id);
                                        }
                                      : null,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text('Add transaction'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => repo.resolve(m.id),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text('Dismiss'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
