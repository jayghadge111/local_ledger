import '../../shared/widgets/text_button_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/small_repositories.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';

/// Names and UPI IDs that mean "me", plus the accounts found in messages —
/// the evidence used to recognise transfers between the user's own accounts.
class OwnIdentifiersScreen extends ConsumerStatefulWidget {
  const OwnIdentifiersScreen({super.key});

  @override
  ConsumerState<OwnIdentifiersScreen> createState() =>
      _OwnIdentifiersScreenState();
}

class _OwnIdentifiersScreenState extends ConsumerState<OwnIdentifiersScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    await ref.read(ownIdentifiersRepositoryProvider).add(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identifiers =
        ref.watch(ownIdentifiersProvider).value ?? const <OwnIdentifier>[];
    final db = ref.watch(databaseProvider);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('My other names & UPI IDs')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other names and UPI IDs that are you',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your full name is set in Settings. Add anything else the bank might print '
                    'for you — a nickname, a spelling variant, or a UPI ID like yourname@okhdfcbank. '
                    'A payment mentioning one of these is a Self Transfer, not spending or income.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _add(),
                          decoration: const InputDecoration(
                            hintText: 'Name or UPI ID',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _add,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  for (final i in identifiers)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.value),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        color: dangerColor(context),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref
                            .read(ownIdentifiersRepositoryProvider)
                            .delete(i.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: StreamBuilder<List<Account>>(
                stream: db.select(db.accounts).watch(),
                builder: (context, snapshot) {
                  final accounts = snapshot.data ?? const <Account>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accounts found in your messages',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (accounts.isEmpty)
                        Text(
                          'None yet — they appear as bank messages are imported.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      for (final a in accounts)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(switch (a.accountType) {
                            'forex' => Icons.currency_exchange_rounded,
                            'cash' => Icons.payments_rounded,
                            'bank' => Icons.account_balance_rounded,
                            _ => Icons.credit_card_rounded,
                          }),
                          title: Text(a.name),
                          subtitle: Text(a.accountType),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
