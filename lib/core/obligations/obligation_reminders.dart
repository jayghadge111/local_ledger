import '../../core/money_format.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import 'obligation_repository.dart';

NumberFormat get _money => appCurrency(symbol: '₹',
  decimalDigits: 0,
);

/// How many reminder slots an obligation can use (3 days / 1 day / the day).
const reminderSlots = 3;

/// The notification id for one reminder of one obligation. Stable, so
/// scheduling again replaces the earlier reminder instead of adding another.
int reminderIdFor(String obligationId, int slot) =>
    0x60000000 | ((obligationId.hashCode & 0x07ffffff) << 2) | (slot & 3);

/// A notification id for "this debit failed" (shown once, at once).
int failureIdFor(String obligationId) =>
    0x58000000 | (obligationId.hashCode & 0x07ffffff);

class PlannedReminder {
  const PlannedReminder({
    required this.slot,
    required this.when,
    required this.title,
    required this.body,
  });

  final int slot;
  final DateTime when;
  final String title;
  final String body;
}

/// Which reminders [o] should have, from [now] on. Empty unless it is still
/// upcoming: a paid, failed or missed one needs none (and has them cancelled).
///
/// * a scheduled debit or EMI: the morning before and the morning of;
/// * a card bill: three days before, the day before, and the day.
///
/// Reminders already in the past are left out, so a notice that arrives the
/// day before still gets its day-of reminder.
List<PlannedReminder> planReminders(Obligation o, DateTime now) {
  final due = o.dueDate;
  if (o.status != ObligationStatus.upcoming || due == null) return const [];
  final day = DateTime(due.year, due.month, due.day);
  DateTime at(int daysBefore) =>
      DateTime(day.year, day.month, day.day - daysBefore, 9);

  final amount = o.amountMinor == null
      ? null
      : _money.format(o.amountMinor! / 100);
  final who = o.biller ?? _defaultName(o);
  final from = o.accountLast4 == null ? '' : ' from A/c ••${o.accountLast4}';
  final ref = o.refLast4 == null ? '' : ' ••${o.refLast4}';

  late final List<(int slot, int daysBefore, String title, String body)> plan;
  switch (o.kind) {
    case 'card_due':
      final min = o.minDueMinor == null
          ? ''
          : ' · minimum ${_money.format(o.minDueMinor! / 100)}';
      plan = [
        (0, 3, 'Credit card bill due in 3 days${_amt(amount)}', '$who$ref$min'),
        (1, 1, 'Credit card bill due tomorrow${_amt(amount)}', '$who$ref$min'),
        (2, 0, 'Credit card bill due today${_amt(amount)}', '$who$ref$min'),
      ];
    case 'emi_due':
      plan = [
        (
          1,
          1,
          'EMI due tomorrow${_amt(amount)}',
          '$who$from · keep the account funded',
        ),
        (
          2,
          0,
          'EMI due today${_amt(amount)}',
          '$who$from · keep the account funded',
        ),
      ];
    default: // pre_debit
      plan = [
        (
          1,
          1,
          'Auto-debit tomorrow${_amt(amount)}',
          '$who$from · keep enough balance',
        ),
        (
          2,
          0,
          'Auto-debit today${_amt(amount)}',
          '$who$from · keep enough balance',
        ),
      ];
  }

  return [
    for (final p in plan)
      if (at(p.$2).isAfter(now))
        PlannedReminder(slot: p.$1, when: at(p.$2), title: p.$3, body: p.$4),
  ];
}

String _amt(String? amount) => amount == null ? '' : ': $amount';

String _defaultName(Obligation o) => switch (o.kind) {
  'card_due' => 'Credit card',
  'emi_due' => 'Loan EMI',
  _ => 'Auto-debit',
};

/// The text of the one-off alert for a failed debit.
({String title, String body}) failureText(Obligation o) {
  final amount = o.amountMinor == null
      ? ''
      : ': ${_money.format(o.amountMinor! / 100)}';
  final who = o.biller ?? 'Auto-debit';
  final why = o.reason == null ? '' : ' — ${o.reason}';
  return (
    title: 'Auto-debit failed$amount',
    body: '$who$why. Add money to your account to avoid return charges.',
  );
}
