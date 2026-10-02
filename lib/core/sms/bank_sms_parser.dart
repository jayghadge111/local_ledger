/// Best-effort parse of a bank transaction SMS into structured fields.
/// Covers the common phrasing used by major Indian banks (HDFC, ICICI, SBI,
/// Axis, Kotak, and similar) — real-world SMS formats vary a lot bank to
/// bank, so this is a starting point to refine against real messages, not
/// a guarantee every bank's SMS is parsed correctly.
class ParsedSmsTransaction {
  const ParsedSmsTransaction({
    required this.amountMinor,
    required this.type,
    required this.merchant,
    this.isInternational = false,
  });

  final int amountMinor;
  final String type; // debit, credit
  final String merchant;
  final bool isInternational;
}

/// Known DLT sender-ID fragments for major Indian banks. A real sender ID
/// looks like `VM-HDFCBK` or `AX-ICICIB` — matching by substring on the
/// bank code portion is more robust than trying to replicate the exact DLT
/// template format, which varies by telecom operator.
const _knownBankSenderFragments = [
  'HDFCBK', 'ICICIB', 'SBIINB', 'SBIPSG', 'AXISBK', 'KOTAKB',
  'PNBSMS', 'BOIIND', 'IDFCFB', 'YESBNK', 'CANBNK', 'UNIONB',
  'INDBNK', 'BOBTXN', 'CENTBK',
];

bool looksLikeBankSender(String sender) {
  final upper = sender.toUpperCase();
  return _knownBankSenderFragments.any(upper.contains);
}

final _amountPattern = RegExp(
  r'(?:rs\.?|inr)\s*\.?\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

final _debitKeywords = RegExp(
  r'\b(debited|spent|paid|withdrawn|purchase of)\b',
  caseSensitive: false,
);

final _creditKeywords = RegExp(r'\b(credited|received|deposited)\b', caseSensitive: false);

// Merchant tends to follow one of these connector words.
final _merchantPattern = RegExp(
  r'\b(?:to|at|by|vpa)\s+([A-Za-z0-9@._\-& ]{2,40}?)(?:\s+on\b|\s+ref\b|\.|,|$)',
  caseSensitive: false,
);

final _internationalKeywords = RegExp(
  r'\b(intl|international|foreign currency|forex markup|cross.?currency)\b',
  caseSensitive: false,
);

/// Returns null if the message doesn't look like a parseable transaction
/// alert (balance-check SMS, OTPs, promotional messages, etc.).
ParsedSmsTransaction? parseBankSms(String body) {
  final amountMatch = _amountPattern.firstMatch(body);
  if (amountMatch == null) return null;

  final amountStr = amountMatch.group(1)!.replaceAll(',', '');
  final amount = double.tryParse(amountStr);
  if (amount == null || amount <= 0) return null;

  final String type;
  if (_debitKeywords.hasMatch(body)) {
    type = 'debit';
  } else if (_creditKeywords.hasMatch(body)) {
    type = 'credit';
  } else {
    return null;
  }

  final merchantMatch = _merchantPattern.firstMatch(body);
  final merchant = merchantMatch != null
      ? merchantMatch.group(1)!.trim()
      : (type == 'credit' ? 'Credit' : 'Unknown merchant');

  return ParsedSmsTransaction(
    amountMinor: (amount * 100).round(),
    type: type,
    merchant: merchant,
    isInternational: _internationalKeywords.hasMatch(body),
  );
}
