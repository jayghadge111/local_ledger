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
final _senderCodePattern = RegExp(
  r'^(?:[A-Z]{2}-)?([A-Z0-9]{4,8})(?:-[A-Z])?$',
);

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
  r'(?<![A-Za-z])(rs\.?|inr|₹|' +
      _currencyCodes +
      r')\s*[:.]?\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

// "10.50 USD" — foreign currencies only, to avoid matching stray numbers.
final _suffixAmountPattern = RegExp(
  r'([\d,]+(?:\.\d{1,2})?)\s*(' + _currencyCodes + r')\b',
  caseSensitive: false,
);

// SBI-style: "debited by 150.0", "credited by 5000" — no currency at all.
final _verbAmountPattern = RegExp(
  r'\b(?:debited|credited|debit|credit)\s+(?:by|for|with|of)\s+([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

final _balanceContext = RegExp(
  r'(bal|avl|avail|limit|lmt|outstanding)',
  caseSensitive: false,
);

// "Bal SAR 733.42", "Avl Bal Rs 5,000.00", "Temporary Credit Bal SAR 0" —
// the account's balance, not part of the transaction. Removed before the
// debit/credit wording is read so "Credit Bal" can't pass for a credit.
final _balanceClause = RegExp(
  r'(?:temporary\s+credit\s+|avl\.?\s+|available\s+|total\s+)?(?:bal(?:ance)?|limit)\b[:\s]*(?:[A-Za-z]{2,3}\.?\s*|₹\s*)?[\d,]+(?:\.\d+)?',
  caseSensitive: false,
);

final _strongDebit = RegExp(
  r'\b(debited|spent|withdrawn|paid|purchase|purchased|sent|charged|used (?:at|for)|transacted|swiped)\b',
  caseSensitive: false,
);
final _strongCredit = RegExp(
  r'\b(credited|received|deposited|refunded|refund|reversed|reversal|loaded|reloaded|topped up)\b',
  caseSensitive: false,
);
final _weakDebit = RegExp(
  r'\b(debit|dr|txn of|transaction of|payment of|thank you for using)\b',
  caseSensitive: false,
);
final _weakCredit = RegExp(r'\b(credit(?!\s*card)|cr)\b', caseSensitive: false);

// OTPs, reminders and promos that quote an amount but aren't transactions.
final _notTransaction = RegExp(
  r'\botp\b|one.?time.?password|do not share|never share|verification code|'
  r'will be (?:debited|credited|charged)|is due\b|(?:min(?:imum)?\.?|total) (?:amt|amount) due|'
  r'e-?mandate|pre-?approved|apply now|click here|upgrade|'
  r'converted (?:in)?to (?:an )?emi|emi conversion',
  caseSensitive: false,
);

// A failed payment is not a transaction — unless it's the reversal of one.
final _failedWords = RegExp(
  r'\b(failed|declined|unsuccessful|insufficient)\b',
  caseSensitive: false,
);

// Where a captured name stops: the next field of the message.
const _nameEnd =
    r'(?:\s+on\b|\s+ref(?:no)?\b|\s+upi\b|\s+from\b|\s+via\b|\s+using\b|\s+avl\b|'
    r'\s+bal\b|\s+utr\b|\s*\(|\.\s|\.$|,|$)';

final _merchantPatterns = <RegExp>[
  // "...debited from account 0715 to VPA shop.123@hdfcbank SHOP NAME on 05-04-26"
  // — the payee's name follows the UPI address, which is too long for the
  // general pattern below to reach. Tried first.
  RegExp(
    r"\bvpa\s+\S+\s+([A-Za-z0-9&.' \-]{2,60}?)\s+on\s+\d{1,2}[-/]\d{1,2}[-/]\d{2,4}",
    caseSensitive: false,
  ),
  // "UPI/DR/123456/MERCHANT NAME/HDFC", "UPI/P2M/123456/swiggy/HDFC BANK",
  // "UPI/P2A/123456/NAME SMS BLOCKUPI…"
  RegExp(
    r'\bupi[/\-](?:p2[map]|dr|cr)?[/\-]?\d*[/\-]([A-Za-z0-9 ._@&]+?)(?=[/\-]|\s+(?:sms|bal|avl|not|if|call)\b|$)',
    caseSensitive: false,
  ),
  // "... To MERCHANT On 01/10", "at MERCHANT.", "by NAME,"
  RegExp(
    r'\b(?:to|at|by|vpa|towards)\s+([A-Za-z0-9@._\-& ]{2,40}?)' + _nameEnd,
    caseSensitive: false,
  ),
  // "Info: AMAZON PAY" / "Info- NETFLIX"
  RegExp(
    r'\binfo[:\-]\s*([A-Za-z0-9@._\-&/ ]{2,40}?)(?:\.\s|\.$|,|$)',
    caseSensitive: false,
  ),
  // ICICI account debit: "...on 02-Oct-26; SUNRISE STORE credited. UPI:…"
  RegExp(
    r";\s*([A-Za-z][A-Za-z0-9 .&' \-]{1,40}?)\s+credited\b",
    caseSensitive: false,
  ),
  // ICICI card: "...on 08-Jan-26 on SUNRISE SOFT. Avl Limit…"
  RegExp(
    r"\d{1,2}-[A-Za-z]{3}-\d{2,4}\s+on\s+([A-Za-z][A-Za-z0-9 .&' \-]{1,40}?)(?:\.\s|\.$|,|\s+avl\b|$)",
    caseSensitive: false,
  ),
  // Axis card: "…20:30:00 IST SUNRISE STORE Avl Lmt INR …"
  RegExp(
    r"\bIST\s+([A-Za-z][A-Za-z0-9 .&' \-]{1,40}?)\s+(?:avl|available)\b",
    caseSensitive: false,
  ),
];

final _creditFromPattern = RegExp(
  r'\bfrom\s+([A-Za-z0-9@._\-& ]{2,40}?)(?:\s+in\b|\s+on\b|\s+ref(?:no)?\b|\s+upi\b|\s+via\b|\s+utr\b|\s*\(|\.\s|\.$|,|$)',
  caseSensitive: false,
);

// Words that mean the captured "merchant" is really the user's own account.
final _notMerchant = RegExp(
  r'^(?:a/c|acct|account|your|card|ac\b|xx|\*|bank|the account|sb\b|savings|upi[- ]?ref|ref\b|refno|utr|txn)',
  caseSensitive: false,
);

// Everyday phrases that follow "at"/"to"/"by" in an email's closing lines
// ("available at all times", "reach us at your convenience") — and the
// sending bank's own name ("from ICICI Bank"), which is never the payee.
final _genericPhrase = RegExp(
  r'^(?:all|any|every|this|that|these|those|no|our|us|you|me)\b|'
  r'\btimes?$|\bconvenience$|\bearliest$|\bbank(?: ltd\.?| limited)?$',
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
  r'(?:a/c|\bac\b|acct?\.?|account|card|ending(?:\s+with)?|ends\s+with)\s*(?:no\.?|number)?\s*[:\-]?\s*(?:x+|\*+|\.{2,}|#)?\s*(\d{4})\b',
  caseSensitive: false,
);

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
        .replaceFirst(RegExp(r'^vpa\s+', caseSensitive: false), '')
        .replaceFirst(
          RegExp(
            r'^(?:imps|neft|rtgs|upi)\s+(?:to|from)\s+',
            caseSensitive: false,
          ),
          '',
        );
    if (candidate.length < 2) continue;
    if (_notMerchant.hasMatch(candidate) ||
        _genericPhrase.hasMatch(candidate)) {
      continue;
    }
    if (RegExp(
      r'^(?:rs\.?|inr|₹)?\s*[\d/\-:., ]+$',
      caseSensitive: false,
    ).hasMatch(candidate)) {
      continue;
    }
    return candidate;
  }
  return null;
}

final _loanKind = RegExp(
  r'\b(home|housing|personal|car|auto|vehicle|education|gold|business|two.?wheeler)\s+loan\b',
  caseSensitive: false,
);
final _loanWords = RegExp(
  r'\b(emi|loan|nach|ecs|instal?lment)\b',
  caseSensitive: false,
);

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
  bool has(String pattern) => RegExp(pattern).hasMatch(lower);
  String? transferKind() {
    if (has(r'\bneft\b')) return 'NEFT transfer';
    if (has(r'\bimps\b')) return 'IMPS transfer';
    if (has(r'\brtgs\b')) return 'RTGS transfer';
    return null;
  }

  if (type == 'debit') {
    // SIP and insurance are often debited through NACH too, so they are
    // checked before the loan fallback (which treats bare NACH as an EMI).
    return (has(r'\bsip\b|mutual fund') ? 'Mutual fund SIP' : null) ??
        (has(r'insurance|premium') ? 'Insurance premium' : null) ??
        _loanLabel(body) ??
        (has(r'\batm\b|cash withdrawal') ? 'ATM withdrawal' : null) ??
        (has(r'recharge') ? 'Mobile recharge' : null) ??
        (has(r'fastag|\btoll\b') ? 'FASTag toll' : null) ??
        (has(r'bill ?pay|bbps|\bbill\b') ? 'Bill payment' : null) ??
        (has(r'cheque|\bchq\b') ? 'Cheque payment' : null) ??
        transferKind() ??
        (has(r'service charge|charges|\bfee\b|\bgst\b')
            ? 'Bank charges'
            : null);
  }
  return (has(r'interest') ? 'Interest' : null) ??
      (has(r'dividend') ? 'Dividend' : null) ??
      (has(r'cash deposit|\bcdm\b') ? 'Cash deposit' : null) ??
      (has(r'cheque|\bchq\b') ? 'Cheque deposit' : null) ??
      (has(r'loaded|reloaded|top-?up|topped up') ? 'Card load' : null) ??
      transferKind();
}

// Field-by-field confirmations ("Amount: 18000.00", "Payee Name: …",
// "Transaction Type: DR") rather than a sentence. When present they are
// authoritative — a line like "successfully credited to the beneficiary"
// in such a mail describes the *payee's* side of a payment the user made.
final _structuredType = RegExp(
  r'transaction\s+type\s*:\s*(dr|debit|cr|credit)\b',
  caseSensitive: false,
);
final _structuredAmount = RegExp(
  r'\bamount\s*:\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);
final _structuredCurrency = RegExp(
  r'\bcurrency\s*:\s*([A-Za-z]{3})\b',
  caseSensitive: false,
);
final _structuredStatus = RegExp(
  r'transaction\s+status\s*:\s*([A-Za-z]+)',
  caseSensitive: false,
);

const _fieldLabels =
    r'(?:upi\s+ref(?:erence)?(?:\.?\s*no\.?)?|from\s+vpa|payer\s+name|to\s+vpa|payee\s+name|'
    r'currency|amount|remarks|transaction\s+(?:date|status|type|id)|reason\s+for\s+failure|'
    r'beneficiary|remitter)';

String? _field(String text, String label) {
  final value = RegExp(
    '$label\\s*:\\s*(.+?)(?=\\s+$_fieldLabels\\s*:|\\s*\$)',
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
  const ok = {
    'completed',
    'success',
    'successful',
    'processed',
    'credited',
    'debited',
  };
  if (status != null && !ok.contains(status)) return null; // failed / pending

  final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
  if (amount == null || amount <= 0) return null;

  final isDebit = typeMatch.group(1)!.toLowerCase().startsWith('d');
  // The other party: who the user paid, or who paid the user.
  final party =
      _field(body, isDebit ? r'payee\s+name' : r'payer\s+name') ??
      _field(body, isDebit ? r'to\s+vpa' : r'from\s+vpa');
  final merchant = party
      ?.replaceFirst(
        RegExp(r'^(?:mr|mrs|ms|miss|shri|smt|dr)\.?\s+', caseSensitive: false),
        '',
      )
      .trim();
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

// Where an email's transaction sentence ends and the boilerplate begins.
final _emailFooter = RegExp(
  r'click here|for additional assistance|do not share|never share|if you did not|if you have not|if this (?:transaction )?was not|'
  r'in case you|please call|call us|unsubscribe|disclaimer|this is an auto',
  caseSensitive: false,
);

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
