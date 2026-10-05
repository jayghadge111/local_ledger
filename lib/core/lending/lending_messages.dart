import 'package:intl/intl.dart';

import 'lending_math.dart';

/// How firmly a reminder to someone who owes you money is worded.
enum ReminderTone { friendly, neutral, firm }

/// What someone who borrowed money wants to tell the lender.
enum BorrowerUpdate {
  /// Where I stand: paid so far, still to pay.
  status,

  /// I will pay on a date.
  payOnDate,

  /// Asking for more time, with a new date.
  needMoreTime,
}

/// A rupee amount the way people write it in a message: ₹5,000, or ₹5,000.50
/// when there are paise.
String rupees(int minor) {
  final whole = minor % 100 == 0;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: whole ? 0 : 2,
  ).format(minor / 100);
}

String _day(DateTime d) => DateFormat('d MMM').format(d);
String _dayYear(DateTime d) => DateFormat('d MMM yyyy').format(d);

String _firstName(String person) {
  final first = person.trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? 'there' : first;
}

/// How much of the original amount has been paid, as a whole percent.
///
/// Rounded down, and never 100 until the entry is really settled — "99%"
/// is honest at ₹4,98,000 of ₹5,00,000, "100%" would not be. A first small
/// payment shows as at least 1%.
int paidPercent(LendingBalance b) {
  if (b.isSettled) return 100;
  final total = b.entry.amountMinor;
  if (total <= 0) return 0;
  final raw = (b.paidMinor * 100) ~/ total;
  if (b.paidMinor > 0 && raw == 0) return 1;
  return raw.clamp(0, 99);
}

bool _overdue(LendingBalance b, DateTime now) => b.isOverdue(now);

/// "Paid: ₹2,000 (40%)\nPending: ₹3,000\nDue: 5 Nov", each line only when it
/// says something.
String _figures(LendingBalance b, {required bool lent}) {
  final e = b.entry;
  final lines = [
    '${lent ? 'Paid' : 'Paid back'}: ${rupees(b.paidMinor)} (${paidPercent(b)}%)',
    '${lent ? 'Pending' : 'Still to pay'}: ${rupees(b.outstandingMinor)}',
    if (e.dueDate != null) 'Due: ${_day(e.dueDate!)}',
  ];
  return lines.join('\n');
}

/// The "where things stand" message for an entry, from the user's side.
String statusMessage(LendingBalance b, {DateTime? now}) {
  final e = b.entry;
  final name = _firstName(e.person);
  final total = rupees(e.amountMinor);

  if (b.isLent) {
    if (b.isSettled) {
      return 'Hi $name, just confirming that the $total I lent you on '
          '${_day(e.date)} is fully paid. Thank you!';
    }
    return 'Hi $name, a quick update on the $total I lent you on '
        '${_day(e.date)}:\n\n${_figures(b, lent: true)}\n\nThanks!';
  }

  if (b.isSettled) {
    return 'Hi $name, I\'ve now paid back the full $total you lent me on '
        '${_day(e.date)}. Thank you so much for your help!';
  }
  return 'Hi $name, an update on the $total you lent me on '
      '${_day(e.date)}:\n\n${_figures(b, lent: false)}\n\n'
      'I\'ll keep sending the rest. Thank you for waiting!';
}

/// A reminder to the person who owes the user money. Only for lent entries.
String reminderMessage(LendingBalance b, ReminderTone tone, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final e = b.entry;
  final name = _firstName(e.person);
  final left = rupees(b.outstandingMinor);
  final total = rupees(e.amountMinor);
  final due = e.dueDate;
  final late = _overdue(b, today);

  switch (tone) {
    case ReminderTone.friendly:
      final when = due == null
          ? ''
          : late
          ? ' It was due on ${_day(due)}.'
          : ' It\'s due on ${_day(due)}.';
      return 'Hey $name! Just a gentle reminder about the $left still pending '
          'from the $total I lent you.$when Could you send it over when you '
          'get a chance? Thanks!';
    case ReminderTone.neutral:
      final when = due == null
          ? ''
          : late
          ? ', which was due on ${_day(due)}'
          : ', due on ${_day(due)}';
      return 'Hi $name, a reminder that $left is pending from the $total I '
          'lent you on ${_day(e.date)}$when. Please send it when you can.';
    case ReminderTone.firm:
      if (due == null) {
        return 'Hi $name, the $left from the $total I lent you on '
            '${_day(e.date)} is still pending. Please pay it at the earliest '
            'and let me know once it\'s done.';
      }
      return late
          ? 'Hi $name, the $left from the $total I lent you was due on '
                '${_day(due)} and is still pending. Please pay it at the '
                'earliest and let me know once it\'s done.'
          : 'Hi $name, the $left from the $total I lent you is due on '
                '${_day(due)}. Please make sure it reaches me by then.';
  }
}

/// What someone who borrowed wants to tell the lender. [date] is the day they
/// will pay ([BorrowerUpdate.payOnDate]) or are asking to pay by
/// ([BorrowerUpdate.needMoreTime]); the status message needs none.
String borrowerUpdateMessage(
  LendingBalance b,
  BorrowerUpdate kind, {
  DateTime? date,
  DateTime? now,
}) {
  final e = b.entry;
  final name = _firstName(e.person);
  final left = rupees(b.outstandingMinor);
  final total = rupees(e.amountMinor);

  switch (kind) {
    case BorrowerUpdate.status:
      return statusMessage(b, now: now);
    case BorrowerUpdate.payOnDate:
      final by = date == null ? 'soon' : 'by ${_dayYear(date)}';
      return 'Hi $name, about the $left I still owe you from the $total you '
          'lent me on ${_day(e.date)}: I\'ll pay it $by. Thank you for your '
          'patience!';
    case BorrowerUpdate.needMoreTime:
      final by = date == null ? '' : ' I can pay it by ${_dayYear(date)}.';
      return 'Hi $name, could I please have a little more time for the $left '
          'I still owe you?$by Sorry for the delay, and thank you for '
          'understanding.';
  }
}

/// Offered right after a payment is recorded. Lent: a receipt for what the
/// other person just paid. Borrowed: telling the lender what the user sent.
String paymentMessage(LendingBalance b, int paymentMinor) {
  final e = b.entry;
  final name = _firstName(e.person);
  final paid = rupees(paymentMinor);
  final total = rupees(e.amountMinor);

  if (b.isLent) {
    if (b.isSettled) {
      return 'Hi $name, I\'ve received your $paid. That clears the full '
          '$total — thank you!';
    }
    return 'Hi $name, I\'ve received your $paid, thank you! Paid so far: '
        '${rupees(b.paidMinor)} of $total. ${rupees(b.outstandingMinor)} to go.';
  }

  if (b.isSettled) {
    return 'Hi $name, I\'ve sent you the last $paid. That\'s the full $total '
        'paid back. Thank you so much!';
  }
  return 'Hi $name, I\'ve sent you $paid today. Total paid back so far: '
      '${rupees(b.paidMinor)} of $total. ${rupees(b.outstandingMinor)} to go.';
}
