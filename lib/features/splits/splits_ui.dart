import 'package:flutter/material.dart';

import '../../shared/widgets/centered_dialog_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/small_repositories.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Dialog for splitting one expense with other people. The user's own
/// share is whatever's left; budgets and totals count only that.
Future<void> showSplitSheet(BuildContext context, Transaction transaction) {
  return showDialog(
    context: context,
    builder: (_) =>
        CenteredDialogCard(child: _SplitSheet(transaction: transaction)),
  );
}

class _SplitSheet extends ConsumerStatefulWidget {
  const _SplitSheet({required this.transaction});
  final Transaction transaction;

  @override
  ConsumerState<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<_SplitSheet> {
  final _names = TextEditingController();
  final _person = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _names.dispose();
    _person.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _splitEqually() async {
    final people = _names.text
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (people.isEmpty) return;
    // Equal shares among the others and the user.
    final share = (widget.transaction.amountMinor / (people.length + 1))
        .round();
    final repo = ref.read(splitsRepositoryProvider);
    for (final name in people) {
      await repo.addShare(
        transactionId: widget.transaction.id,
        personName: name,
        shareMinor: share,
      );
    }
    _names.clear();
  }

  Future<void> _addOne() async {
    final name = _person.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) return;
    await ref
        .read(splitsRepositoryProvider)
        .addShare(
          transactionId: widget.transaction.id,
          personName: name,
          shareMinor: (amount * 100).round(),
        );
    _person.clear();
    _amount.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shares =
        (ref.watch(splitSharesProvider).value ?? const <SplitShare>[])
            .where((s) => s.transactionId == widget.transaction.id)
            .toList();
    final others = shares.fold<int>(0, (sum, s) => sum + s.shareMinor);
    final mine = widget.transaction.amountMinor - others;

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
                  Text(
                    'Split ${widget.transaction.merchant}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total ${_money.format(widget.transaction.amountMinor / 100)} · '
                    'your share ${_money.format(mine / 100)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final s in shares)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.personName),
                      subtitle: Text(_money.format(s.shareMinor / 100)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            ref.read(splitsRepositoryProvider).delete(s.id),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _names,
                    decoration: const InputDecoration(
                      labelText: 'Split equally with (comma-separated names)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _splitEqually,
                    child: const Text('Split equally'),
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _person,
                          decoration: const InputDecoration(
                            labelText: 'Person',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Owes (₹)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _addOne,
                    child: const Text('Add share'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
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

/// "Who owes me" — unsettled split shares grouped by person.
class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shares = ref.watch(splitSharesProvider).value ?? const <SplitShare>[];
    final transactions = {
      for (final t
          in ref.watch(transactionsProvider).value ?? const <Transaction>[])
        t.id: t,
    };

    final byPerson = <String, List<SplitShare>>{};
    for (final s in shares) {
      byPerson.putIfAbsent(s.personName, () => []).add(s);
    }
    final people = byPerson.keys.toList()
      ..sort((a, b) => _owed(byPerson[b]!).compareTo(_owed(byPerson[a]!)));

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Splits & IOUs')),
        body: people.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Nothing split yet. Open any expense and tap "Split with others".',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final person in people)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Theme(
                          data: theme.copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              person,
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              _owed(byPerson[person]!) == 0
                                  ? 'All settled'
                                  : 'Owes you ${_money.format(_owed(byPerson[person]!) / 100)}',
                            ),
                            children: [
                              for (final s in byPerson[person]!)
                                CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  value: s.settled,
                                  onChanged: (v) => ref
                                      .read(splitsRepositoryProvider)
                                      .setSettled(s.id, v ?? false),
                                  title: Text(
                                    transactions[s.transactionId]?.merchant ??
                                        'Expense',
                                  ),
                                  subtitle: Text(
                                    '${_money.format(s.shareMinor / 100)} · '
                                    '${transactions[s.transactionId] == null ? '' : DateFormat.yMMMd().format(transactions[s.transactionId]!.date)}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  int _owed(List<SplitShare> shares) => shares
      .where((s) => !s.settled)
      .fold<int>(0, (sum, s) => sum + s.shareMinor);
}
