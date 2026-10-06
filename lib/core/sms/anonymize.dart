import 'dart:convert';

/// Makes a bank message safe to show someone else, keeping its layout.
///
/// The layout is what matters for teaching the parser: where the amount sits,
/// how the payee is introduced, what words surround them. So digits are
/// changed rather than removed, and the amount of the transaction itself is
/// left as it is (the test case needs it). Names can't be told apart from
/// merchants reliably, so the person sharing is asked to check for those.
String anonymizeMessage(String text) {
  var t = text;

  // Email addresses and UPI ids (name@bank).
  t = t.replaceAll(
    RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+'),
    'user@example.com',
  );
  t = t.replaceAll(
    // "debited@SBI UPI" is how some banks write the channel, not a person.
    RegExp(
      r'(?<![\w.])(?!(?:debited|credited|paid|sent|received|trf)@)[\w.\-]{2,}@[a-z]{2,}\b',
      caseSensitive: false,
    ),
    'user@upi',
  );

  // Mobile numbers, with or without the country code.
  t = t.replaceAll(
    RegExp(r'(?<!\d)(?:\+?91[\s-]?)?[6-9]\d{9}(?!\d)'),
    '9876543210',
  );

  // The visible end of a masked account or card: XX4921, *1234, xxxx2627.
  t = t.replaceAllMapped(
    RegExp(r'([xX*]+\s?)(\d{2,6})'),
    (m) => '${m[1]}${_digits(m[2]!.length)}',
  );

  // "A/c 123456789012", "card no 4111...", "loan no. P405PSA3761027".
  t = t.replaceAllMapped(
    RegExp(
      r'((?:a/c|acct|account|card|loan|policy|folio)\s*(?:no\.?|number|num|ending(?:\s+with)?)?\s*[:#]?\s*)((?=[A-Za-z0-9]*\d)[A-Za-z0-9]{4,})',
      caseSensitive: false,
    ),
    (m) => '${m[1]}${_digits(m[2]!.length)}',
  );

  // Balances and limits: "Avl bal Rs 70,703.19", "Available limit: INR 90,000".
  t = t.replaceAllMapped(
    RegExp(
      r'((?:avl\.?\s*bal(?:ance)?|available\s*(?:bal(?:ance)?|limit|credit\s*limit)|bal(?:ance)?|limit)\s*[:\-]?\s*(?:rs\.?|inr|₹)?\s*)(\d[\d,]*(?:\.\d+)?)',
      caseSensitive: false,
    ),
    (m) => '${m[1]}${_sameShape(m[2]!)}',
  );

  // Reference numbers, UTRs, transaction ids: any long run of digits.
  t = t.replaceAllMapped(
    RegExp(r'(?<![\d.,])\d{8,}(?![\d])'),
    (m) => _digits(m[0]!.length),
  );

  // "Dear Jayesh," / "Hi Rahul Kumar,".
  t = t.replaceAllMapped(
    RegExp(r'\b(Dear|Hi|Hello)\s+(?!Customer|User|Sir|Madam|Cardmember)[A-Z][A-Za-z.]*(?:\s+[A-Z][A-Za-z.]*){0,2}'),
    (m) => '${m[1]} Customer',
  );

  return t;
}

/// Digits 1-2-3… of the given length, so the shape survives.
String _digits(int n) {
  const seq = '1234567890';
  return List.generate(n, (i) => seq[i % 10]).join();
}

/// A number written the same way (commas, decimals) with other digits.
String _sameShape(String number) {
  var i = 0;
  return number.replaceAllMapped(RegExp(r'\d'), (_) => '${(++i) % 9 + 1}');
}

/// A ready-to-paste entry for the `canaries` list of the rules file: the
/// message and what the parser must make of it. [type] null means "not a
/// transaction".
String canaryJson({
  required String text,
  String? type,
  int? amountMinor,
  String? merchantContains,
}) {
  final map = {
    'text': text,
    'expect': {
      'type': type,
      'amountMinor': ?amountMinor,
      if (merchantContains != null && merchantContains.trim().isNotEmpty)
        'merchantContains': merchantContains.trim().toLowerCase(),
    },
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}
