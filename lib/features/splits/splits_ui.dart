import '../../shared/widgets/text_button_styles.dart';
import '../../core/money_format.dart';

import 'package:flutter/material.dart';

import '../../shared/widgets/centered_dialog_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/db/small_repositories.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/placeholder_body.dart';

NumberFormat get _money => appCurrency(symbol: '₹', decimalDigits: 2);

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

/// One person in the split being drafted. [amount] only matters in custom mode.
class _Person {
  _Person(this.name, [String amount = ''])
    : amount = TextEditingController(text: amount);
  final String name;
  final TextEditingController amount;
}

class _SplitSheetState extends ConsumerState<_SplitSheet> {
  final _name = TextEditingController();
  final _people = <_Person>[];
  bool _equal = true;
  bool _loaded = false;
  bool _saving = false;
  bool _hadShares = false;

  int get _total => widget.transaction.amountMinor;

  /// Everyone, you included, pays the same.
  int get _equalShare => (_total / (_people.length + 1)).round();

  @override
  void dispose() {
    _name.dispose();
    for (final p in _people) {
      p.amount.dispose();
    }
    super.dispose();
  }

  /// Starts from what is already saved for this expense, once it has loaded.
  void _seed(List<SplitShare> saved) {
    _loaded = true;
    if (saved.isEmpty) return;
    _hadShares = true;
    for (final s in saved) {
      _people.add(
        _Person(s.personName, (s.shareMinor / 100).toStringAsFixed(2)),
      );
    }
    _equal = saved.every((s) => s.shareMinor == _equalShare);
  }

  void _addNames() {
    final names = _name.text
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty);
    setState(() {
      for (final n in names) {
        if (_people.any((p) => p.name.toLowerCase() == n.toLowerCase())) {
          continue;
        }
        _people.add(_Person(n));
      }
      _name.clear();
    });
  }

  void _setMode(bool equal) {
    setState(() {
      // Custom amounts start from the equal split, so the user only adjusts.
      if (!equal && _equal) {
        for (final p in _people) {
          p.amount.text = (_equalShare / 100).toStringAsFixed(2);
        }
      }
      _equal = equal;
    });
  }

  int _shareOf(_Person p) {
    if (_equal) return _equalShare;
    final v = double.tryParse(p.amount.text.trim());
    return v == null || v < 0 ? 0 : (v * 100).round();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(splitsRepositoryProvider).replaceShares(
        widget.transaction.id,
        [
          for (final p in _people)
            if (_shareOf(p) > 0) (name: p.name, shareMinor: _shareOf(p)),
        ],
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = ref.watch(splitSharesProvider).value;
    if (!_loaded && saved != null) {
      _seed([
        for (final s in saved)
          if (s.transactionId == widget.transaction.id) s,
      ]);
    }
    final others = _people.fold<int>(0, (sum, p) => sum + _shareOf(p));
    final mine = _total - others;
    final tooMuch = mine < 0;
    final canSave = !_saving && !tooMuch && (_people.isNotEmpty || _hadShares);

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
                    'Total ${_money.format(_total / 100)} · '
                    'your share ${_money.format(mine / 100)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tooMuch
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Who is splitting with you?',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addNames(),
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Add person',
                        onPressed: _addNames,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add several at once with commas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_people.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Split equally'),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Custom amounts'),
                        ),
                      ],
                      selected: {_equal},
                      onSelectionChanged: (s) => _setMode(s.first),
                    ),
                    const SizedBox(height: 8),
                    for (final p in _people)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            if (_equal)
                              Text(
                                _money.format(_equalShare / 100),
                                style: theme.textTheme.bodyLarge,
                              )
                            else
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: p.amount,
                                  onChanged: (_) => setState(() {}),
                                  textAlign: TextAlign.end,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    prefixText: '₹ ',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            IconButton(
                              tooltip: 'Remove ${p.name}',
                              color: dangerColor(context),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () =>
                                  setState(() => _people.remove(p)),
                            ),
                          ],
                        ),
                      ),
                    if (tooMuch)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'These add up to more than the total.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: canSave ? _save : null,
                          child: Text(
                            _people.isEmpty && _hadShares
                                ? 'Remove split'
                                : 'Save split',
                          ),
                        ),
                      ),
                    ],
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
        appBar: AppBar(title: const Text('Split')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _pickExpense(context, ref),
          icon: const Icon(Icons.call_split_rounded),
          label: const Text('New split'),
        ),
        body: people.isEmpty
            ? const PlaceholderBody(
                icon: Icons.call_split_rounded,
                title: 'Nothing split yet',
                subtitle: 'Paid a bill for a group? Tap New split, pick the expense and add your friends. You can also split from any transaction.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Owed to you',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _money.format(
                                    people.fold<int>(
                                          0,
                                          (sum, p) => sum + _owed(byPerson[p]!),
                                        ) /
                                        100,
                                  ),
                                  style: theme.textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${people.length} ${people.length == 1 ? 'person' : 'people'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
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

  /// Choose which expense to split: the latest spending, searchable.
  Future<void> _pickExpense(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<Transaction>(
      context: context,
      builder: (_) => const CenteredDialogCard(child: _ExpensePicker()),
    );
    if (picked != null && context.mounted) {
      await showSplitSheet(context, picked);
    }
  }

  int _owed(List<SplitShare> shares) => shares
      .where((s) => !s.settled)
      .fold<int>(0, (sum, s) => sum + s.shareMinor);
}

/// The list behind "New split".
class _ExpensePicker extends ConsumerStatefulWidget {
  const _ExpensePicker();

  @override
  ConsumerState<_ExpensePicker> createState() => _ExpensePickerState();
}

class _ExpensePickerState extends ConsumerState<_ExpensePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final spending = [
      for (final t
          in ref.watch(transactionsProvider).value ?? const <Transaction>[])
        if (t.type == 'debit' &&
            t.kind == 'normal' &&
            (q.isEmpty || t.merchant.toLowerCase().contains(q)))
          t,
    ].take(40).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Which expense?', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: spending.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No matching expenses.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final t in spending)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  t.merchant,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  DateFormat.yMMMd().format(t.date),
                                ),
                                trailing: Text(
                                  _money.format(t.amountMinor / 100),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                onTap: () => Navigator.of(context).pop(t),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
