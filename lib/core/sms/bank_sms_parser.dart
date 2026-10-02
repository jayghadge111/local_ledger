import 'bank_sender_codes.dart';

/// Best-effort parse of a bank transaction SMS into structured fields.
/// Covers the common phrasing used by Indian banks — real-world formats
/// vary a lot bank to bank, so unparseable-but-transaction-like messages
/// are queued for manual review rather than silently dropped (see
/// [looksLikeUnparsedTransaction]).
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
/// of `VM-HDFCBK-S` — so it can be checked against [knownBankSenderCodes]
/// with an exact `Set` lookup. The operator/circle prefix and the -S/-T
/// category suffix are both optional in the pattern since not every
/// message strictly follows the full template.
final _senderCodePattern = RegExp(r'^(?:[A-Z]{2}-)?([A-Z0-9]{4,8})(?:-[A-Z])?$');

/// The bank code inside a sender ID (`VM-HDFCBK-S` -> `HDFCBK`), or the
/// whole uppercased sender when it doesn't follow the DLT template.
String bankCodeOf(String sender) {
  final upper = sender.toUpperCase().trim();
  return _senderCodePattern.firstMatch(upper)?.group(1) ?? upper;
}

bool looksLikeBankSender(String sender) =>
    knownBankSenderCodes.contains(bankCodeOf(sender));

const _currencyCodes =
    'usd|sar|eur|gbp|aed|sgd|aud|cad|jpy|cny|thb|myr|chf|qar|kwd|bhd|omr|hkd|nzd|idr|lkr|npr';

// "Rs.20", "INR 20.0", "₹500", "USD 10.50". The lookbehind stops "Hours 5"
// matching as "rs 5".
final _prefixAmountPattern = RegExp(
  r'(?<![A-Za-z])(rs\.?|inr|₹|' + _currencyCodes + r')\s*\.?\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

// "10.50 USD" — foreign currencies only, to avoid matching stray numbers.
final _suffixAmountPattern = RegExp(
  r'([\d,]+(?:\.\d{1,2})?)\s*(' + _currencyCodes + r')\b',
  caseSensitive: false,
);

final _balanceContext = RegExp(r'(bal|avl|avail|limit|outstanding)', caseSensitive: false);

// "Bal SAR 733.42", "Avl Bal Rs 5,000.00", "Temporary Credit Bal SAR 0" —
// the account's balance, not part of the transaction. Removed before the
// debit/credit wording is read so "Credit Bal" can't pass for a credit.
final _balanceClause = RegExp(
  r'(?:temporary\s+credit\s+|avl\.?\s+|available\s+|total\s+)?(?:bal(?:ance)?|limit)\b[:\s]*(?:[A-Za-z]{2,3}\.?\s*|₹\s*)?[\d,]+(?:\.\d+)?',
  caseSensitive: false,
);

final _strongDebit = RegExp(
  r'\b(debited|spent|withdrawn|paid|purchase|purchased|sent|charged|used at|transacted|swiped)\b',
  caseSensitive: false,
);
final _strongCredit = RegExp(
  r'\b(credited|received|deposited|refunded|refund|reversed|reversal)\b',
  caseSensitive: false,
);
final _weakDebit = RegExp(r'\b(debit|dr|txn of|transaction of|payment of)\b', caseSensitive: false);
final _weakCredit = RegExp(r'\b(credit(?!\s*card)|cr)\b', caseSensitive: false);

// OTPs, reminders and promos that quote an amount but aren't transactions.
final _notTransaction = RegExp(
  r'\botp\b|one.?time.?password|do not share|never share|verification code|'
  r'will be (?:debited|credited|charged)|is due\b|(?:min(?:imum)?\.?|total) (?:amt|amount) due|'
  r'e-?mandate|pre-?approved|apply now|click here|upgrade',
  caseSensitive: false,
);

// A failed payment is not a transaction — unless it's the reversal of one.
final _failedWords = RegExp(r'\b(failed|declined|unsuccessful|insufficient)\b', caseSensitive: false);

final _merchantPatterns = <RegExp>[
  // "UPI/DR/123456/MERCHANT NAME/HDFC"
  RegExp(r'\bupi[/\-](?:dr|cr)?[/\-]?\d*[/\-]([A-Za-z0-9 ._@&]+?)(?:[/\-]|$)', caseSensitive: false),
  // "... To MERCHANT On 01/10", "at MERCHANT.", "by NAME,"
  RegExp(
    r'\b(?:to|at|by|vpa)\s+([A-Za-z0-9@._\-& ]{2,40}?)(?:\s+on\b|\s+ref\b|\s+upi\b|\.\s|\.$|,|$)',
    caseSensitive: false,
  ),
  // "Info: AMAZON PAY" / "Info- NETFLIX"
  RegExp(r'\binfo[:\-]\s*([A-Za-z0-9@._\-&/ ]{2,40}?)(?:\.\s|\.$|,|$)', caseSensitive: false),
];

final _creditFromPattern = RegExp(
  r'\bfrom\s+([A-Za-z0-9@._\-& ]{2,40}?)(?:\s+on\b|\s+ref\b|\s+upi\b|\.\s|\.$|,|$)',
  caseSensitive: false,
);

// Words that mean the captured "merchant" is really the user's own account.
final _notMerchant = RegExp(
  r'^(?:a/c|acct|account|your|card|ac\b|xx|\*|bank|the account|sb\b|savings)',
  caseSensitive: false,
);

final _refundWords = RegExp(
  r'\b(refund(?:ed)?|revers(?:ed|al)|cancell?ed|returned|chargeback)\b',
  caseSensitive: false,
);

final _forexWords = RegExp(r'\bforex\b', caseSensitive: false);
final _prepaidWords = RegExp(r'\bprepaid\b', caseSensitive: false);
final _creditCardWords = RegExp(r'\bcredit\s+card\b', caseSensitive: false);
final _debitCardWords = RegExp(r'\bdebit\s+card\b', caseSensitive: false);
final _cardWords = RegExp(r'\bcard\b', caseSensitive: false);

String _accountKind(String body) {
  if (_forexWords.hasMatch(body)) return 'forex';
  if (_prepaidWords.hasMatch(body)) return 'prepaid';
  if (_creditCardWords.hasMatch(body)) return 'credit_card';
  if (_debitCardWords.hasMatch(body)) return 'debit_card';
  return _cardWords.hasMatch(body) ? 'card' : 'bank';
}

final _internationalKeywords = RegExp(
  r'\b(intl|international|foreign currency|forex markup|cross.?currency)\b',
  caseSensitive: false,
);

final _last4Pattern = RegExp(
  r'(?:a/c|acct?\.?|account|card|ending(?:\s+with)?|ends\s+with)\s*(?:no\.?|number)?\s*[:\-]?\s*(?:x+|\*+|\.{2,}|#)?\s*(\d{4})\b',
  caseSensitive: false,
);

({String currency, double amount})? _findAmount(String body) {
  for (final m in _prefixAmountPattern.allMatches(body)) {
    final from = m.start < 14 ? 0 : m.start - 14;
    if (_balanceContext.hasMatch(body.substring(from, m.start))) continue;
    final amount = double.tryParse(m.group(2)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) continue;
    final symbol = m.group(1)!.toLowerCase();
    final currency = (symbol.startsWith('rs') || symbol == 'inr' || symbol == '₹')
        ? 'INR'
        : symbol.toUpperCase();
    return (currency: currency, amount: amount);
  }
  for (final m in _suffixAmountPattern.allMatches(body)) {
    final amount = double.tryParse(m.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) continue;
    return (currency: m.group(2)!.toUpperCase(), amount: amount);
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
  if (_weakDebit.hasMatch(body)) return 'debit';
  if (_weakCredit.hasMatch(body)) return 'credit';
  return null;
}

String? _merchant(String body, String type) {
  final candidates = <RegExpMatch>[
    for (final p in _merchantPatterns) ...p.allMatches(body),
    if (type == 'credit') ..._creditFromPattern.allMatches(body),
  ];
  for (final m in candidates) {
    final candidate = m.group(1)!.trim();
    if (candidate.length < 2) continue;
    if (_notMerchant.hasMatch(candidate)) continue;
    if (RegExp(r'^[\d/\-: ]+$').hasMatch(candidate)) continue;
    return candidate;
  }
  return null;
}

/// Returns null if the message doesn't look like a parseable transaction
/// alert (balance-check SMS, OTPs, promotional messages, etc.).
ParsedSmsTransaction? parseBankSms(String body) {
  if (_notTransaction.hasMatch(body)) return null;

  final amount = _findAmount(body);
  if (amount == null) return null;

  final type = _type(body);
  if (type == null) return null;

  if (_failedWords.hasMatch(body) && !_strongCredit.hasMatch(body)) return null;

  final merchant = _merchant(body, type) ??
      (type == 'credit' ? 'Credit' : 'Unknown merchant');

  return ParsedSmsTransaction(
    amountMinor: (amount.amount * 100).round(),
    type: type,
    merchant: merchant,
    isInternational: amount.currency != 'INR' || _internationalKeywords.hasMatch(body),
    currency: amount.currency,
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
  if (_findAmount(body) == null) return false;
  return parseBankSms(body) == null;
}
