import '../obligations/obligation_classifier.dart';
import '../rules/parser_rules.dart';

/// Best-effort parse of a bank transaction SMS into structured fields.
/// Covers the common phrasing used by Indian banks — real-world formats
/// vary a lot bank to bank, so unparseable-but-transaction-like messages
/// are queued for manual review rather than silently dropped (see
/// [looksLikeUnparsedTransaction]).
/// The patterns the parser reads — always the rules currently in force.
ParserPatterns get _p => ParserRules.current.parser;

class ParsedSmsTransaction {
  const ParsedSmsTransaction({
    required this.amountMinor,
    required this.type,
    required this.merchant,
    this.isInternational = false,
    this.currency = 'INR',
    this.last4,
    this.refundHint = false,
    this.accountKind,
  });

  final int amountMinor; // minor units of [currency]
  final String type; // debit, credit
  final String merchant; // raw merchant text as the bank wrote it
  final bool isInternational;
  final String currency;

  /// Last four digits of the account/card the message is about, if present.
  final String? last4;

  /// The message mentions a refund/reversal/cancellation.
  final bool refundHint;

  /// What the message says the account is: forex, prepaid, credit_card,
  /// debit_card, or plain card/bank when it doesn't say more.
  final String? accountKind;
}

/// Extracts the bank-code portion of a DLT SMS header — e.g. `HDFCBK` out
/// of `VM-HDFCBK-S` — so it can be checked against the known sender codes
/// with an exact `Set` lookup. The operator/circle prefix and the -S/-T
/// category suffix are both optional in the pattern since not every
/// message strictly follows the full template.
RegExp get _senderCodePattern => _p.senderCode;

/// The bank code inside a sender ID (`VM-HDFCBK-S` -> `HDFCBK`), or the
/// whole uppercased sender when it doesn't follow the DLT template.
String bankCodeOf(String sender) {
  final upper = sender.toUpperCase().trim();
  return _senderCodePattern.firstMatch(upper)?.group(1) ?? upper;
}

bool looksLikeBankSender(String sender) =>
    ParserRules.current.senderCodes.contains(bankCodeOf(sender));

// "Rs.20", "INR 20.0", "₹500", "USD 10.50". The lookbehind stops "Hours 5"
// matching as "rs 5".
RegExp get _prefixAmountPattern => _p.prefixAmount;

// "10.50 USD" — foreign currencies only, to avoid matching stray numbers.
RegExp get _suffixAmountPattern => _p.suffixAmount;

// SBI-style: "debited by 150.0", "credited by 5000" — no currency at all.
RegExp get _verbAmountPattern => _p.verbAmount;

RegExp get _balanceContext => _p.balanceContext;

// "Bal SAR 733.42", "Avl Bal Rs 5,000.00", "Temporary Credit Bal SAR 0" —
// the account's balance, not part of the transaction. Removed before the
// debit/credit wording is read so "Credit Bal" can't pass for a credit.
RegExp get _balanceClause => _p.balanceClause;

RegExp get _strongDebit => _p.strongDebit;
RegExp get _strongCredit => _p.strongCredit;
RegExp get _weakDebit => _p.weakDebit;
RegExp get _weakCredit => _p.weakCredit;

// OTPs, reminders and promos that quote an amount but aren't transactions.
RegExp get _notTransaction => _p.notTransaction;

// A failed payment is not a transaction — unless it's the reversal of one.
RegExp get _failedWords => _p.failedWords;

// Where a captured name stops: the next field of the message.

List<RegExp> get _merchantPatterns => _p.merchantPatterns;

RegExp get _creditFromPattern => _p.creditFrom;

// Words that mean the captured "merchant" is really the user's own account.
RegExp get _notMerchant => _p.notMerchant;

// Everyday phrases that follow "at"/"to"/"by" in an email's closing lines
// ("available at all times", "reach us at your convenience") — and the
// sending bank's own name ("from ICICI Bank"), which is never the payee.
RegExp get _genericPhrase => _p.genericPhrase;

RegExp get _refundWords => _p.refundWords;

RegExp get _forexWords => _p.forexWords;
RegExp get _prepaidWords => _p.prepaidWords;
RegExp get _creditCardWords => _p.creditCardWords;
RegExp get _debitCardWords => _p.debitCardWords;
RegExp get _cardWords => _p.cardWords;

String _accountKind(String body) {
  if (_forexWords.hasMatch(body)) return 'forex';
  if (_prepaidWords.hasMatch(body)) return 'prepaid';
  if (_creditCardWords.hasMatch(body)) return 'credit_card';
  if (_debitCardWords.hasMatch(body)) return 'debit_card';
  return _cardWords.hasMatch(body) ? 'card' : 'bank';
}

RegExp get _internationalKeywords => _p.internationalKeywords;

RegExp get _last4Pattern => _p.last4;

({String currency, double amount})? _findAmount(String body) {
  for (final m in _prefixAmountPattern.allMatches(body)) {
    final from = m.start < 14 ? 0 : m.start - 14;
    if (_balanceContext.hasMatch(body.substring(from, m.start))) continue;
    final amount = double.tryParse(m.group(2)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) continue;
    final symbol = m.group(1)!.toLowerCase();
    final currency =
        (symbol.startsWith('rs') || symbol == 'inr' || symbol == '₹')
        ? 'INR'
        : symbol.toUpperCase();
    return (currency: currency, amount: amount);
  }
  for (final m in _suffixAmountPattern.allMatches(body)) {
    final amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) continue;
    return (currency: m.group(2)!.toUpperCase(), amount: amount);
  }
  for (final m in _verbAmountPattern.allMatches(body)) {
    final amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) continue;
    return (currency: 'INR', amount: amount);
  }
  return null;
}

String? _type(String rawBody) {
  final body = rawBody.replaceAll(_balanceClause, ' ');
  final strongDebit = _strongDebit.firstMatch(body);
  final strongCredit = _strongCredit.firstMatch(body);
  if (strongDebit != null && strongCredit != null) {
    return strongDebit.start <= strongCredit.start ? 'debit' : 'credit';
  }
  if (strongDebit != null) return 'debit';
  if (strongCredit != null) return 'credit';
  // "Dr. from A/C … and Cr. to …" names both: the first one is the user's side.
  final weakDebit = _weakDebit.firstMatch(body);
  final weakCredit = _weakCredit.firstMatch(body);
  if (weakDebit != null && weakCredit != null) {
    return weakDebit.start <= weakCredit.start ? 'debit' : 'credit';
  }
  if (weakDebit != null) return 'debit';
  if (weakCredit != null) return 'credit';
  return null;
}

String? _merchant(String body, String type) {
  final candidates = <RegExpMatch>[
    for (final p in _merchantPatterns) ...p.allMatches(body),
    if (type == 'credit') ..._creditFromPattern.allMatches(body),
  ];
  for (final m in candidates) {
    var candidate = m
        .group(1)!
        .trim()
        .replaceFirst(_p.stripVpa, '')
        .replaceFirst(_p.stripChannel, '');
    if (candidate.length < 2) continue;
    if (_notMerchant.hasMatch(candidate) ||
        _genericPhrase.hasMatch(candidate)) {
      continue;
    }
    if (_p.numericOnly.hasMatch(candidate)) continue;
    return candidate;
  }
  return null;
}

RegExp get _loanKind => _p.loanKind;
RegExp get _loanWords => _p.loanWords;

/// "Home Loan EMI" / "Loan EMI" for a loan-repayment alert that names no
/// payee, so it lands in Bills rather than as an unknown merchant.
String? _loanLabel(String body) {
  if (!_loanWords.hasMatch(body)) return null;
  final kind = _loanKind.firstMatch(body)?.group(1);
  if (kind == null) return 'Loan EMI';
  final word = kind.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ' ');
  return '${word[0].toUpperCase()}${word.substring(1)} Loan EMI';
}

/// A readable name for an alert that names no payee but says what the money
/// was for — ATM cash, a recharge, a toll, an NEFT transfer, interest — so it
/// isn't left as "Unknown merchant" (and can be categorized).
String? _purposeLabel(String body, String type) {
  final lower = body.toLowerCase();
  final list = type == 'debit' ? _p.debitPurposes : _p.creditPurposes;
  for (final entry in list) {
    if (entry.isLoan) {
      // SIP and insurance are often debited through NACH too, so they sit
      // before this spot in the list: the loan check treats bare NACH as an EMI.
      final loan = _loanLabel(body);
      if (loan != null) return loan;
    } else if (entry.regex!.hasMatch(lower)) {
      return entry.label;
    }
  }
  return null;
}

// Field-by-field confirmations ("Amount: 18000.00", "Payee Name: …",
// "Transaction Type: DR") rather than a sentence. When present they are
// authoritative — a line like "successfully credited to the beneficiary"
// in such a mail describes the *payee's* side of a payment the user made.
RegExp get _structuredType => _p.structuredType;
RegExp get _structuredAmount => _p.structuredAmount;
RegExp get _structuredCurrency => _p.structuredCurrency;
RegExp get _structuredStatus => _p.structuredStatus;

String? _field(String text, String label) {
  final value = RegExp(
    _p.structuredFieldTemplate
        .replaceAll('{label}', label)
        .replaceAll('{fieldLabels}', _p.structuredFieldLabels),
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();
  return value == null || value.isEmpty || value.toUpperCase() == 'NA'
      ? null
      : value;
}

ParsedSmsTransaction? _parseStructured(String body) {
  final typeMatch = _structuredType.firstMatch(body);
  final amountMatch = _structuredAmount.firstMatch(body);
  if (typeMatch == null || amountMatch == null) return null;

  final status = _structuredStatus.firstMatch(body)?.group(1)?.toLowerCase();
  if (status != null && !_p.structuredOkStatuses.contains(status)) {
    return null; // failed / pending
  }

  final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
  if (amount == null || amount <= 0) return null;

  final isDebit = typeMatch.group(1)!.toLowerCase().startsWith('d');
  // The other party: who the user paid, or who paid the user.
  String? party;
  for (final label in isDebit ? _p.debitPartyLabels : _p.creditPartyLabels) {
    party ??= _field(body, label);
  }
  final merchant = party?.replaceFirst(_p.partyTitle, '').trim();
  final currency =
      _structuredCurrency.firstMatch(body)?.group(1)?.toUpperCase() ?? 'INR';

  return ParsedSmsTransaction(
    amountMinor: (amount * 100).round(),
    type: isDebit ? 'debit' : 'credit',
    merchant: (merchant == null || merchant.isEmpty)
        ? (isDebit ? 'Unknown merchant' : 'Credit')
        : merchant,
    isInternational: currency != 'INR',
    currency: currency,
    accountKind: 'bank',
  );
}

/// Returns null if the message doesn't look like a parseable transaction
/// alert (balance-check SMS, OTPs, promotional messages, etc.).
ParsedSmsTransaction? parseBankSms(String body) {
  final structured = _parseStructured(body);
  if (structured != null) return structured;
  if (_structuredType.hasMatch(body)) return null; // a failed/pending record

  if (_notTransaction.hasMatch(body)) return null;

  // "Will be debited on…", "mandate registered", "EMI is due", "debit
  // failed": notices about money, not a transaction (see ObligationKind).
  if (classifyObligation(body) != null) return null;

  final amount = _findAmount(body);
  if (amount == null) return null;

  final type = _type(body);
  if (type == null) return null;

  if (_failedWords.hasMatch(body) && !_strongCredit.hasMatch(body)) return null;

  final merchant =
      _merchant(body, type) ??
      _purposeLabel(body, type) ??
      (type == 'credit' ? 'Credit' : 'Unknown merchant');

  return ParsedSmsTransaction(
    amountMinor: (amount.amount * 100).round(),
    type: type,
    merchant: merchant,
    isInternational:
        amount.currency != 'INR' || _internationalKeywords.hasMatch(body),
    currency: amount.currency,
    last4: _last4Pattern.firstMatch(body)?.group(1),
    refundHint: type == 'credit' && _refundWords.hasMatch(body),
    accountKind: _accountKind(body),
  );
}

/// A transaction read from a message layout the user taught the app (see
/// `template_learning.dart`): the template supplied the amount, direction
/// and, if it has one, the payee; everything else is read the usual way.
ParsedSmsTransaction parsedFromLearned({
  required String body,
  required String type,
  required int amountMinor,
  String? merchant,
}) {
  return ParsedSmsTransaction(
    amountMinor: amountMinor,
    type: type,
    merchant:
        (merchant == null || merchant.trim().length < 2
            ? null
            : merchant.trim()) ??
        _purposeLabel(body, type) ??
        (type == 'credit' ? 'Credit' : 'Unknown merchant'),
    isInternational: _internationalKeywords.hasMatch(body),
    currency: 'INR',
    last4: _last4Pattern.firstMatch(body)?.group(1),
    refundHint: type == 'credit' && _refundWords.hasMatch(body),
    accountKind: _accountKind(body),
  );
}

/// The first non-balance amount in [body] in minor units, for prefilling the
/// form when a message couldn't be fully parsed.
int? extractAmountMinor(String body) {
  final found = _findAmount(body);
  return found == null ? null : (found.amount * 100).round();
}

/// True for a message from a bank that quotes an amount in a
/// transaction-ish way but that [parseBankSms] couldn't classify — the ones
/// worth showing the user for manual review. OTPs and promos are excluded
/// so the review queue isn't flooded with noise.
bool looksLikeUnparsedTransaction(String body) {
  if (_notTransaction.hasMatch(body)) return false;
  if (classifyObligation(body) != null) return false;
  if (_findAmount(body) == null) return false;
  return parseBankSms(body) == null;
}

// Where an email's transaction sentence ends and the boilerplate begins.
RegExp get _emailFooter => _p.emailFooter;

/// For long text (an email): the stretch around the first debit/credit
/// wording that sits next to an amount — the sentence that actually reports
/// the transaction. Everything outside it (greetings, "click here" links,
/// "never share your OTP" footers) is dropped, so boilerplate can't make a
/// genuine alert look like an OTP or promo. Falls back to the start of the
/// text when no such sentence is found.
String focusTransactionText(String text) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // A field-by-field record is one block: keep all of it (up to the footer).
  if (_structuredType.hasMatch(flat)) {
    final footer = _emailFooter.firstMatch(flat);
    final record = footer == null ? flat : flat.substring(0, footer.start);
    return (record.length > 1200 ? record.substring(0, 1200) : record).trim();
  }

  final keywords = [
    ..._strongDebit.allMatches(flat),
    ..._strongCredit.allMatches(flat),
  ]..sort((a, b) => a.start.compareTo(b.start));
  for (final k in keywords) {
    final from = k.start < 220 ? 0 : k.start - 220;
    final to = k.end + 320 > flat.length ? flat.length : k.end + 320;
    var window = flat.substring(from, to);
    // Cut at the first disclaimer/footer phrase after the keyword.
    final cut = _emailFooter.firstMatch(window.substring(k.end - from));
    if (cut != null) window = window.substring(0, (k.end - from) + cut.start);
    if (_findAmount(window) != null) return window.trim();
  }
  return flat.length > 600 ? flat.substring(0, 600) : flat;
}
