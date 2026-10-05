import '../email/bank_email_matcher.dart';
import '../rules/parser_rules.dart';
import 'obligation_classifier.dart';

export 'obligation_classifier.dart';
import '../sms/bank_names.dart';
import '../sms/bank_sms_parser.dart';

/// A message read as an auto-debit notice. These are never spending: they say
/// a debit is *coming*, *set up* or *failed*.
class ParsedObligation {
  const ParsedObligation({
    required this.kind,
    this.amountMinor,
    this.isMaxAmount = false,
    this.minDueMinor,
    this.dueDate,
    this.biller,
    this.umrn,
    this.accountLast4,
    this.refLast4,
    this.refType,
    this.frequency,
    this.reason,
  });

  final ObligationKind kind;

  /// The amount to be debited, the total due on a card, or — for a mandate —
  /// its cap when [isMaxAmount].
  final int? amountMinor;
  final bool isMaxAmount;

  /// Minimum due on a card bill.
  final int? minDueMinor;

  /// When the debit or payment falls due (a mandate's next debit date).
  final DateTime? dueDate;

  /// Who is paid: "NIPPON INDIA MUTUAL FUND", "HDFC Bank Credit Card"…
  final String? biller;

  /// Mandate reference (UMRN, or a UPI AutoPay mandate id).
  final String? umrn;

  /// Last 4 digits of the bank account the debit is from.
  final String? accountLast4;

  /// Last 4 digits of the card, or the loan number, the message is about.
  final String? refLast4;

  /// 'card' or 'loan' — what [refLast4] refers to.
  final String? refType;

  final String? frequency;

  /// Why a debit failed ("Insufficient Funds").
  final String? reason;

  @override
  String toString() =>
      'ParsedObligation(${kind.key}, amount: $amountMinor, due: $dueDate, '
      'biller: $biller, umrn: $umrn, acct: $accountLast4, ref: $refLast4)';
}

ObligationPatterns get _o => ParserRules.current.obligations;

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

DateTime? _dateOf(RegExpMatch m) {
  final day = int.tryParse(m.group(1)!);
  final named = m.group(2);
  final month = named != null
      ? _months[named.toLowerCase().substring(0, 3)]
      : int.tryParse(m.group(3) ?? '');
  var year = int.tryParse(m.group(4)!);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  if (day < 1 || day > 31 || month < 1 || month > 12) return null;
  if (year < 2000 || year > 2100) return null;
  final date = DateTime(year, month, day);
  // "31-02-26" rolls over into March: that is not a real date.
  return date.month == month ? date : null;
}

/// Every date in [text] with where it starts: `07-OCT-26`, `05-Oct-2026`,
/// `18/10/2026`, `24 Oct 2026`, `05Mar24`.
List<({DateTime date, int start})> findDates(String text) {
  final out = <({DateTime date, int start})>[];
  for (final m in _o.date.allMatches(text)) {
    final d = _dateOf(m);
    if (d != null) out.add((date: d, start: m.start));
  }
  return out;
}

int? _minor(String? raw) {
  if (raw == null) return null;
  final v = double.tryParse(raw.replaceAll(',', ''));
  return v == null || v <= 0 ? null : (v * 100).round();
}

String? _last4(String? digits) => digits == null || digits.length < 4
    ? null
    : digits.substring(digits.length - 4);

String? _frequency(String? raw) {
  if (raw == null) return null;
  final w = raw.trim().toLowerCase();
  if (w.startsWith('month')) return 'Monthly';
  if (w.startsWith('week')) return 'Weekly';
  if (w.startsWith('quarter')) return 'Quarterly';
  if (w.startsWith('year') || w.startsWith('annual')) return 'Yearly';
  return raw.trim();
}

String? _cleanBiller(String raw) {
  var c = raw.trim().replaceAll(RegExp(r"^[ .,\-]+|[ .,\-]+$"), '');
  // "TOWARDS LIC ECS Mandate" -> "LIC"; "…FINANCE LTD EMI" -> "…FINANCE LTD".
  for (var i = 0; i < 3; i++) {
    final trimmed = c.replaceFirst(_o.billerTrim, '').trim();
    if (trimmed == c) break;
    c = trimmed;
  }
  if (c.length < 2) return null;
  if (_o.billerRejectStart.hasMatch(c) || _o.billerRejectEnd.hasMatch(c)) {
    return null;
  }
  if (RegExp(r'\b(?:ending|a/c)\b', caseSensitive: false).hasMatch(c)) {
    return null;
  }
  return c;
}

String? _biller(String t, ObligationKind kind, String? sender) {
  if (kind == ObligationKind.cardDue) {
    final m = _o.cardIssuer.firstMatch(t);
    if (m != null) {
      final name = m.group(0)!.trim();
      final lower = name.toLowerCase();
      return lower == 'onecard' || lower == 'scapia'
          ? name
          : '$name Credit Card';
    }
    return _senderName(sender);
  }

  final patterns = [
    ..._o.billers,
    if (kind == ObligationKind.mandate || kind == ObligationKind.preDebit)
      _o.billerFallback,
  ];
  for (final p in patterns) {
    for (final m in p.allMatches(t)) {
      final c = _cleanBiller(m.group(1)!);
      if (c != null) return c;
    }
  }

  if (kind == ObligationKind.emiDue || kind == ObligationKind.bounce) {
    // The lender's name: the bank that sent it, or its signature line, or
    // "your DMI Finance loan" — but not the *type* of loan ("Two Wheeler").
    final sent = _senderName(sender);
    if (sent != null) return sent;
    final sig = _o.signature.firstMatch(t)?.group(1)?.trim();
    if (sig != null && sig.length > 2) return sig;
    final loan = _o.yourLoan.firstMatch(t)?.group(1)?.trim();
    if (loan != null && !_o.loanTypeWord.hasMatch(loan)) return loan;
  }
  return null;
}

String? _senderName(String? sender) {
  if (sender == null) return null;
  final known = sender.contains('@')
      ? looksLikeBankEmail(sender)
      : looksLikeBankSender(sender);
  return known ? bankDisplayName(sender) : null;
}

/// Reads an auto-debit notice, or returns null if [body] isn't one — or is
/// one that says too little to act on (a marketing "Set up AutoPay!" with no
/// amount, bank or date).
///
/// [sender] (an SMS sender id) lets an EMI notice that never names the lender
/// be filed under the bank that sent it.
ParsedObligation? parseObligation(String body, {String? sender}) {
  final t = flatText(body);
  final kind = classifyObligation(t);
  if (kind == null) return null;

  int? amount;
  var isMax = false;
  int? minDue;

  if (kind == ObligationKind.mandate) {
    final max = _o.maxAmount.firstMatch(t);
    if (max != null) {
      amount = _minor(max.group(1));
      isMax = amount != null;
    } else {
      amount = _minor(_o.amount.firstMatch(t)?.group(1));
    }
  } else if (kind == ObligationKind.cardDue) {
    amount =
        _minor(_o.totalDue.firstMatch(t)?.group(1)) ??
        _minor(_o.amount.firstMatch(t)?.group(1));
    minDue = _minor(_o.minDue.firstMatch(t)?.group(1));
  } else {
    amount = _minor(_o.amount.firstMatch(t)?.group(1));
  }

  // The date the money moves (or the card bill falls due).
  DateTime? due;
  final dates = findDates(t);
  if (kind == ObligationKind.mandate) {
    final lead = _o.nextDebitLead.firstMatch(t);
    if (lead != null) {
      due = dates.where((d) => d.start == lead.end).firstOrNull?.date;
    }
  } else if (dates.isNotEmpty) {
    if (kind == ObligationKind.cardDue) {
      for (final lead in _o.dueDateLead.allMatches(t)) {
        final hit = dates.where((d) => d.start == lead.end).firstOrNull;
        if (hit != null) {
          due = hit.date;
          break;
        }
      }
    }
    due ??= dates.first.date;
  }

  final umrn =
      _o.umrn.firstMatch(t)?.group(1) ?? _o.mandateId.firstMatch(t)?.group(1);

  // The bank account, the card, and the loan number are different things.
  final loan = _o.loanRef.firstMatch(t)?.group(1);
  var account = _last4(_o.account.firstMatch(t)?.group(1));
  final cardMatch = _o.card.firstMatch(t);
  final card = cardMatch?.group(1) ?? cardMatch?.group(2);
  String? ref;
  String? refType;
  if (kind == ObligationKind.cardDue && card != null) {
    ref = card;
    refType = 'card';
  } else if ((kind == ObligationKind.emiDue || kind == ObligationKind.bounce) &&
      loan != null) {
    ref = loan;
    refType = 'loan';
    // "Loan A/C ending 9012" names the loan, not the bank account.
    if (account != null && loan.endsWith(account)) account = null;
  }

  final parsed = ParsedObligation(
    kind: kind,
    amountMinor: amount,
    isMaxAmount: isMax,
    minDueMinor: minDue,
    dueDate: due,
    biller: _biller(t, kind, sender),
    umrn: umrn,
    accountLast4: account,
    refLast4: ref,
    refType: refType,
    frequency: _frequency(
      _o.frequency
          .firstMatch(t)
          ?.groups([1, 2, 3])
          .firstWhere((g) => g != null, orElse: () => null),
    ),
    reason: kind == ObligationKind.bounce
        ? (_o.reason.firstMatch(t)?.group(1)?.trim() ??
              (RegExp(r'returned\s+unpaid', caseSensitive: false).hasMatch(t)
                  ? 'Returned unpaid'
                  : null))
        : null,
  );
  return _worthKeeping(parsed) ? parsed : null;
}

/// A notice is only useful if it says what, when or for whom.
bool _worthKeeping(ParsedObligation o) {
  switch (o.kind) {
    case ObligationKind.mandate:
      return o.umrn != null || (o.amountMinor != null && o.biller != null);
    case ObligationKind.preDebit:
    case ObligationKind.emiDue:
      return o.amountMinor != null && o.dueDate != null;
    case ObligationKind.cardDue:
      return o.amountMinor != null && o.dueDate != null;
    case ObligationKind.bounce:
      return o.amountMinor != null || o.biller != null;
  }
}
