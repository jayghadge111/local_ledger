import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/lending/lending_math.dart';
import '../../core/lending/lending_repository.dart';
import '../../shared/widgets/centered_dialog_card.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/glass_background.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/text_button_styles.dart';
import '../../core/lending/lending_messages.dart';
import '../../core/theme/app_theme.dart';
import 'lending_share_dialog.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Money lent to and borrowed from people — entered by hand, with part
/// repayments and due dates (which raise reminders).
class LendingScreen extends ConsumerStatefulWidget {
  const LendingScreen({super.key});

  @override
  ConsumerState<LendingScreen> createState() => _LendingScreenState();
}

class _LendingScreenState extends ConsumerState<LendingScreen> {
  String? _direction; // null = all
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(lendingBalancesProvider);
    final totals = ref.watch(lendingTotalsProvider);
    final list = [
      for (final b in all)
        if ((_direction == null || b.entry.direction == _direction) &&
            (_showSettled || !b.isSettled))
          b,
    ];

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Lend & borrow')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showLendingEntryDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add entry'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            FadeSlideIn(
              child: Row(
                children: [
                  Expanded(
                    child: _TotalCard(
                      label: "You'll get",
                      amountMinor: totals.owedToMeMinor,
                      color: Colors.green,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TotalCard(
                      label: 'You owe',
                      amountMinor: totals.iOweMinor,
                      color: theme.colorScheme.error,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String?>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(value: 'lent', label: Text('I lent')),
                      ButtonSegment(
                        value: 'borrowed',
                        label: Text('I borrowed'),
                      ),
                    ],
                    selected: {_direction},
                    onSelectionChanged: (s) =>
                        setState(() => _direction = s.first),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _showSettled = !_showSettled),
                icon: Icon(
                  _showSettled
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(_showSettled ? 'Hide settled' : 'Show settled'),
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      all.isEmpty
                          ? 'Nothing lent or borrowed yet'
                          : 'Nothing here',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap “Add entry” to note money you gave or took, with an optional due date for a reminder.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 30 * i.clamp(0, 10)),
                  child: LendingCard(balance: list[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amountMinor,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amountMinor;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money.format(amountMinor / 100),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// One person's entry: who, how much is left, when it's due, and quick actions.
class LendingCard extends ConsumerWidget {
  const LendingCard({super.key, required this.balance});

  final LendingBalance balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final e = balance.entry;
    final now = DateTime.now();
    final days = balance.daysUntilDue(now);
    final overdue = balance.isOverdue(now);
    final color = balance.isLent ? Colors.green : theme.colorScheme.error;
    final dueText = e.dueDate == null
        ? null
        : balance.isSettled
        ? null
        : overdue
        ? '${-days!}d overdue'
        : days == 0
        ? 'Due today'
        : 'Due in ${days}d · ${DateFormat('d MMM').format(e.dueDate!)}';

    return GlassCard(
      onTap: () => showLendingDetail(context, balance.entry.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(
                  balance.isLent
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.person, style: theme.textTheme.titleMedium),
                    Text(
                      '${balance.isLent ? 'You lent' : 'You borrowed'} ${_money.format(e.amountMinor / 100)} · ${DateFormat('d MMM yyyy').format(e.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balance.isSettled
                        ? 'Settled'
                        : _money.format(balance.outstandingMinor / 100),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: balance.isSettled
                          ? theme.colorScheme.onSurfaceVariant
                          : color,
                    ),
                  ),
                  if (!balance.isSettled)
                    Text(
                      balance.isLent ? 'to get' : 'to pay',
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ),
          if (!balance.isSettled && balance.paidMinor > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (balance.paidMinor / e.amountMinor).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.outline,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_money.format(balance.paidMinor / 100)} paid back so far',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (dueText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    (overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                dueText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: overdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (!balance.isSettled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      showLendingPaymentDialog(context, balance.entry.id),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(balance.isLent ? 'Got money back' : 'I paid'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref
                      .read(lendingRepositoryProvider)
                      .setSettled(e.id, true),
                  child: const Text('Mark settled'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---- add / edit ----

Future<void> showLendingEntryDialog(
  BuildContext context, {
  LendingEntry? existing,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => CenteredDialogCard(child: _EntryForm(existing: existing)),
  );
}

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({this.existing});

  final LendingEntry? existing;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  final _formKey = GlobalKey<FormState>();
  late String _direction = widget.existing?.direction ?? 'lent';
  late final _person = TextEditingController(
    text: widget.existing?.person ?? '',
  );
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.amountMinor / 100).toStringAsFixed(0),
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late DateTime? _due = widget.existing?.dueDate;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: due
          ? (_due ?? DateTime.now().add(const Duration(days: 7)))
          : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => due ? _due = picked : _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(lendingRepositoryProvider);
    final minor = (double.parse(_amount.text.trim()) * 100).round();
    if (widget.existing == null) {
      await repo.addEntry(
        person: _person.text,
        direction: _direction,
        amountMinor: minor,
        date: _date,
        dueDate: _due,
        note: _note.text,
      );
    } else {
      await repo.updateEntry(
        widget.existing!.id,
        person: _person.text,
        direction: _direction,
        amountMinor: minor,
        date: _date,
        dueDate: _due,
        note: _note.text,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.existing != null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            editing ? 'Edit entry' : 'New entry',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'lent',
                          label: Text('I lent'),
                          icon: Icon(Icons.south_west_rounded),
                        ),
                        ButtonSegment(
                          value: 'borrowed',
                          label: Text('I borrowed'),
                          icon: Icon(Icons.north_east_rounded),
                        ),
                      ],
                      selected: {_direction},
                      onSelectionChanged: (s) =>
                          setState(() => _direction = s.first),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _person,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _direction == 'lent'
                            ? 'Lent to'
                            : 'Borrowed from',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0)
                            ? 'Enter a valid amount'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pick(due: false),
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                            label: Text(DateFormat('d MMM yyyy').format(_date)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pick(due: true),
                            icon: const Icon(Icons.alarm_rounded, size: 18),
                            label: Text(
                              _due == null
                                  ? 'Set due date (reminder)'
                                  : 'Due ${DateFormat('d MMM yyyy').format(_due!)}',
                            ),
                          ),
                        ),
                        if (_due != null)
                          IconButton(
                            tooltip: 'Remove due date',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _due = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _save,
                            child: Text(editing ? 'Save changes' : 'Add entry'),
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
      ),
    );
  }
}

// ---- repayment ----

Future<void> showLendingPaymentDialog(BuildContext context, String entryId) {
  return showDialog<void>(
    context: context,
    builder: (_) => CenteredDialogCard(child: _PaymentForm(entryId: entryId)),
  );
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.entryId});

  final String entryId;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = ref
        .watch(lendingBalancesProvider)
        .where((b) => b.entry.id == widget.entryId)
        .firstOrNull;
    if (balance == null) return const SizedBox.shrink();
    final left = balance.outstandingMinor;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        balance.isLent
                            ? 'Money back from ${balance.entry.person}'
                            : 'Paid to ${balance.entry.person}',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  '${_money.format(left / 100)} still ${balance.isLent ? 'to get' : 'to pay'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    errorText: _error,
                    suffix: TextButton(
                      onPressed: () =>
                          _amount.text = (left / 100).toStringAsFixed(0),
                      child: const Text('Full'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(DateFormat('d MMM yyyy').format(_date)),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () async {
                          final n = double.tryParse(_amount.text.trim());
                          if (n == null || n <= 0) {
                            setState(() => _error = 'Enter a valid amount');
                            return;
                          }
                          final minor = (n * 100).round();
                          if (minor > left) {
                            setState(
                              () => _error =
                                  'More than the ${_money.format(left / 100)} left',
                            );
                            return;
                          }
                          await ref
                              .read(lendingRepositoryProvider)
                              .addPayment(
                                widget.entryId,
                                amountMinor: minor,
                                date: _date,
                              );
                          if (!context.mounted) return;
                          // Offer to tell the other person, once this
                          // dialog has closed.
                          final host = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          Navigator.of(context).pop();
                          if (host.mounted) {
                            await showLendingShare(
                              host.context,
                              widget.entryId,
                              kind: LendingShareKind.payment,
                              paymentMinor: minor,
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- detail ----

Future<void> showLendingDetail(BuildContext context, String entryId) {
  return showDialog<void>(
    context: context,
    builder: (_) => CenteredDialogCard(child: _Detail(entryId: entryId)),
  );
}

/// "40% paid", a bar, and the paid / pending amounts — worded for whichever
/// side the user is on.
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.balance});

  final LendingBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = balance;
    final percent = paidPercent(b);
    final settled = b.isSettled;
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget figure(String label, String value, {bool end = false}) => Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          settled
              ? 'Settled'
              : b.isLent
              ? '$percent% paid'
              : 'You\'ve paid back $percent%',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: theme.colorScheme.outline,
            color: settled ? Colors.green : ChartColors.of(context).accent,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            figure(
              b.isLent ? 'Paid' : 'Paid back',
              _money.format(b.paidMinor / 100),
            ),
            figure(
              b.isLent ? 'Pending' : 'Still owe',
              _money.format(b.outstandingMinor / 100),
              end: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balance = ref
        .watch(lendingBalancesProvider)
        .where((b) => b.entry.id == entryId)
        .firstOrNull;
    if (balance == null) return const SizedBox.shrink();
    final payments = [
      for (final p
          in ref.watch(lendingPaymentsProvider).value ??
              const <LendingPayment>[])
        if (p.entryId == entryId) p,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final e = balance.entry;
    final repo = ref.read(lendingRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                      Expanded(
                        child: Text(
                          e.person,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Text(
                    '${balance.isLent ? 'Lent' : 'Borrowed'} ${_money.format(e.amountMinor / 100)} on ${DateFormat('d MMM yyyy').format(e.date)}'
                    '${e.dueDate == null ? '' : ' · due ${DateFormat('d MMM yyyy').format(e.dueDate!)}'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (e.note != null) ...[
                    const SizedBox(height: 6),
                    Text(e.note!, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 14),
                  _ProgressBlock(balance: balance),
                  const SizedBox(height: 12),
                  Text(
                    balance.isLent ? 'Repayments' : 'Payments you made',
                    style: theme.textTheme.labelLarge,
                  ),
                  if (payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'None yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final p in payments)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_money.format(p.amountMinor / 100)),
                      subtitle: Text(DateFormat('d MMM yyyy').format(p.date)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Remove',
                        onPressed: () => repo.deletePayment(p.id),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => showLendingShare(
                            context,
                            e.id,
                            kind: LendingShareKind.status,
                          ),
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Share status'),
                        ),
                      ),
                      if (!balance.isSettled) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showLendingShare(
                              context,
                              e.id,
                              kind: LendingShareKind.message,
                            ),
                            icon: Icon(
                              balance.isLent
                                  ? Icons.notifications_active_outlined
                                  : Icons.send_rounded,
                              size: 18,
                            ),
                            label: Text(
                              balance.isLent ? 'Remind' : 'Send update',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!balance.isSettled) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => showLendingPaymentDialog(context, e.id),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                        balance.isLent ? 'Record payment' : 'I paid some',
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Edit, settle and delete: same style, evenly spaced.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showLendingEntryDialog(context, existing: e);
                        },
                        child: const Text('Edit'),
                      ),
                      if (balance.isSettled)
                        TextButton(
                          onPressed: () => repo.setSettled(e.id, false),
                          child: const Text('Reopen'),
                        )
                      else
                        TextButton(
                          onPressed: () => repo.setSettled(e.id, true),
                          child: const Text('Mark settled'),
                        ),
                      TextButton(
                        style: dangerTextButtonStyle(context),
                        onPressed: () async {
                          await repo.deleteEntry(e.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Delete'),
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
