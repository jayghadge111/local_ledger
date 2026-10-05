import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/lending/lending_math.dart';
import '../../core/lending/lending_messages.dart';
import '../../core/lending/lending_repository.dart';
import '../../core/lending/lending_share.dart';
import '../../shared/widgets/centered_dialog_card.dart';
import '../../shared/widgets/glass_surface.dart';
import 'lending_status_card.dart';

/// Which message the dialog opens with.
enum LendingShareKind {
  /// Where things stand: paid, pending, due. Text or an image card.
  status,

  /// A nudge to the person who owes the user (lent) or an update to the
  /// person the user owes (borrowed).
  message,

  /// Offered right after a payment is recorded.
  payment,
}

/// Opens the share dialog for one lend/borrow entry. The message is built
/// from that entry alone; the user can edit it, then picks WhatsApp, Telegram,
/// SMS or any other app from the phone's share sheet and sends it from there.
Future<void> showLendingShare(
  BuildContext context,
  String entryId, {
  required LendingShareKind kind,
  int paymentMinor = 0,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => CenteredDialogCard(
      child: LendingShareDialog(
        entryId: entryId,
        kind: kind,
        paymentMinor: paymentMinor,
      ),
    ),
  );
}

class _Choice {
  const _Choice(this.label, this.icon, {this.needsDate = false});
  final String label;
  final IconData icon;
  final bool needsDate;
}

class LendingShareDialog extends ConsumerStatefulWidget {
  const LendingShareDialog({
    super.key,
    required this.entryId,
    required this.kind,
    this.paymentMinor = 0,
    this.now,
  });

  final String entryId;
  final LendingShareKind kind;
  final int paymentMinor;

  /// What counts as today (replaceable in tests).
  final DateTime? now;

  @override
  ConsumerState<LendingShareDialog> createState() => _LendingShareDialogState();
}

class _LendingShareDialogState extends ConsumerState<LendingShareDialog> {
  final _controller = TextEditingController();
  final _cardKey = GlobalKey();
  int _choice = 0;
  DateTime? _date;
  bool _sharing = false;
  bool _composed = false;

  static const _lentTones = [
    _Choice('Friendly', Icons.sentiment_satisfied_alt_rounded),
    _Choice('Neutral', Icons.sentiment_neutral_rounded),
    _Choice('Firm', Icons.priority_high_rounded),
  ];
  static const _borrowerUpdates = [
    _Choice('Where I stand', Icons.task_alt_rounded),
    _Choice('I\'ll pay on a date', Icons.event_rounded, needsDate: true),
    _Choice('Need more time', Icons.more_time_rounded, needsDate: true),
  ];

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Choice> _choices(LendingBalance b) {
    if (widget.kind != LendingShareKind.message) return const [];
    return b.isLent ? _lentTones : _borrowerUpdates;
  }

  /// Whether the current message is the plain status, which always goes with
  /// the picture of the status card.
  bool _isStatus(LendingBalance b) =>
      widget.kind == LendingShareKind.status ||
      (widget.kind == LendingShareKind.message && !b.isLent && _choice == 0);

  DateTime _defaultDate(LendingBalance b) {
    final due = b.entry.dueDate;
    final base = due != null && due.isAfter(_today) ? due : _today;
    return DateTime(base.year, base.month, base.day + (_choice == 2 ? 7 : 0));
  }

  String _compose(LendingBalance b) {
    switch (widget.kind) {
      case LendingShareKind.status:
        return statusMessage(b, now: _today);
      case LendingShareKind.payment:
        return paymentMessage(b, widget.paymentMinor);
      case LendingShareKind.message:
        if (b.isLent) {
          return reminderMessage(b, ReminderTone.values[_choice], now: _today);
        }
        final choice = _borrowerUpdates[_choice];
        return borrowerUpdateMessage(
          b,
          BorrowerUpdate.values[_choice],
          date: choice.needsDate ? (_date ??= _defaultDate(b)) : null,
          now: _today,
        );
    }
  }

  void _regenerate(LendingBalance b) {
    _controller.text = _compose(b);
  }

  Future<void> _pickDate(LendingBalance b) async {
    final start = _date ?? _defaultDate(b);
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isBefore(_today) ? _today : start,
      firstDate: DateTime(_today.year, _today.month, _today.day),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _regenerate(b);
    });
  }

  Future<void> _share(LendingBalance b) async {
    setState(() => _sharing = true);
    try {
      final share = ref.read(lendingShareProvider);
      if (_isStatus(b)) {
        final png = await captureCardPng(_cardKey);
        await share(text: _controller.text, png: png);
      } else {
        await share(text: _controller.text);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = ref
        .watch(lendingBalancesProvider)
        .where((b) => b.entry.id == widget.entryId)
        .firstOrNull;
    if (balance == null) return const SizedBox.shrink();

    if (!_composed) {
      _composed = true;
      _regenerate(balance);
    }

    final person = balance.entry.person;
    final choices = _choices(balance);
    final status = _isStatus(balance);
    final needsDate =
        choices.isNotEmpty && !balance.isLent && choices[_choice].needsDate;

    final title = switch (widget.kind) {
      LendingShareKind.status => 'Share status',
      LendingShareKind.payment => 'Tell $person?',
      LendingShareKind.message =>
        balance.isLent ? 'Remind $person' : 'Update $person',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                        child: Text(title, style: theme.textTheme.titleLarge),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  if (choices.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < choices.length; i++)
                          ChoiceChip(
                            avatar: Icon(choices[i].icon, size: 16),
                            label: Text(choices[i].label),
                            selected: _choice == i,
                            onSelected: (_) => setState(() {
                              _choice = i;
                              _date = null;
                              _regenerate(balance);
                            }),
                          ),
                      ],
                    ),
                  ],
                  if (needsDate) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(balance),
                      icon: const Icon(Icons.event_rounded, size: 18),
                      label: Text(
                        'Pay by ${DateFormat('d MMM yyyy').format(_date ?? _defaultDate(balance))}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (status) ...[
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: LendingStatusCard(
                            balance: balance,
                            now: _today,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _controller,
                    minLines: status ? 3 : 4,
                    maxLines: 9,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: status
                          ? 'Message with the picture'
                          : 'Message',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the text to edit it.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _sharing ? null : () => _share(balance),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(_sharing ? 'Opening…' : 'Send via…'),
                  ),

                  if (widget.kind == LendingShareKind.payment)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Not now'),
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
