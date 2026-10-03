/// Teaching the parser from a correction.
///
/// When the user fixes a transaction — or enters one by hand from a message
/// the parser couldn't read — we know the right answer for that message. This
/// turns the message into a *template*: the same text with the amount and the
/// payee replaced by capture groups, and every reference number, date or
/// account mask loosened, so the next message with the same layout is read
/// correctly without the user doing anything.
library;

/// The loosened regex for a message layout, or null if the message is too
/// short or generic to be a safe template (it would match unrelated messages).
String? buildTemplatePattern({
  required String body,
  required int amountMinor,
  String? merchant,
}) {
  final text = normalizeMessage(body);

  final amount = _findAmountToken(text, amountMinor);
  if (amount == null) return null;

  var merchantRange = merchant == null
      ? null
      : _findMerchantRange(text, merchant, amount);

  final ranges = <({int start, int end, String group})>[
    (
      start: amount.start,
      end: amount.end,
      group: r'(?<amt>\d[\d,]*(?:\.\d{1,2})?)',
    ),
    if (merchantRange != null)
      (
        start: merchantRange.start,
        end: merchantRange.end,
        group: r'(?<m>\S[^\n]{1,58}?)',
      ),
  ]..sort((a, b) => a.start.compareTo(b.start));

  final out = StringBuffer('^');
  var cursor = 0;
  var fixedLetters = 0;
  for (final r in ranges) {
    final gap = text.substring(cursor, r.start);
    fixedLetters += RegExp(r'[A-Za-z]').allMatches(gap).length;
    out.write(_loosen(gap));
    out.write(r.group);
    cursor = r.end;
  }
  final tail = text.substring(cursor);
  fixedLetters += RegExp(r'[A-Za-z]').allMatches(tail).length;
  out.write(_loosen(tail));
  out.write(r'$');

  // Too little fixed wording means the template would fit almost any message.
  if (fixedLetters < 25) return null;
  return out.toString();
}

class TemplateMatch {
  const TemplateMatch({required this.amountMinor, this.merchant});

  final int amountMinor;
  final String? merchant;
}

/// Reads [body] with a stored template pattern, or null if it doesn't fit.
TemplateMatch? matchTemplate(String body, RegExp compiled) {
  final m = compiled.firstMatch(normalizeMessage(body));
  if (m == null) return null;
  final amount = double.tryParse(
    (m.namedGroup('amt') ?? '').replaceAll(',', ''),
  );
  if (amount == null || amount <= 0) return null;
  String? merchant;
  try {
    merchant = m.namedGroup('m')?.trim().replaceAll(RegExp(r'[\s.,;:]+$'), '');
  } catch (_) {
    merchant = null; // template has no merchant group
  }
  return TemplateMatch(
    amountMinor: (amount * 100).round(),
    merchant: (merchant == null || merchant.isEmpty) ? null : merchant,
  );
}

RegExp compileTemplate(String pattern) => RegExp(pattern, caseSensitive: false);

/// One line, single spaces — so line breaks and spacing differences between
/// two messages of the same layout don't matter.
String normalizeMessage(String body) =>
    body.replaceAll(RegExp(r'\s+'), ' ').trim();

// ---- internals ----

({int start, int end})? _findAmountToken(String text, int amountMinor) {
  for (final m in RegExp(r'\d[\d,]*(?:\.\d{1,2})?').allMatches(text)) {
    final v = double.tryParse(m.group(0)!.replaceAll(',', ''));
    if (v != null && (v * 100).round() == amountMinor) {
      return (start: m.start, end: m.end);
    }
  }
  return null;
}

// Words that end a payee's name in a bank message.
const _stopWords = {
  'on',
  'ref',
  'upi',
  'avl',
  'bal',
  'utr',
  'via',
  'using',
  'from',
  'is',
  'has',
  'was',
  'for',
  'dated',
  'date',
  'txn',
  'transaction',
  'info',
  'if',
  'not',
  'call',
  'sms',
  'to',
  'at',
  'by',
};

({int start, int end})? _findMerchantRange(
  String text,
  String merchant,
  ({int start, int end}) amount,
) {
  final needle = normalizeMessage(merchant);
  if (needle.length < 3) return null;
  final i = text.toLowerCase().indexOf(needle.toLowerCase());
  if (i < 0) return null;

  // Start at the beginning of the word the match falls in.
  var start = i;
  while (start > 0 && text[start - 1] != ' ') {
    start--;
  }
  // Extend over the rest of the name: whole words until a stop word,
  // punctuation or the end.
  var end = i + needle.length;
  while (end < text.length &&
      text[end] != ' ' &&
      !',;()/'.contains(text[end])) {
    end++;
  }
  while (end < text.length) {
    final m = RegExp(r' ([^ ,;()/]+)').matchAsPrefix(text, end);
    if (m == null) break;
    final word = m.group(1)!;
    final bare = word.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
    if (_stopWords.contains(bare) ||
        RegExp(r'\d').hasMatch(word) ||
        word.endsWith('.')) {
      break;
    }
    end = m.end;
  }
  // A name that runs into the amount isn't a name.
  if (start < amount.end && end > amount.start) return null;
  return (start: start, end: end);
}

/// Escapes fixed text, but loosens the parts that change message to message:
/// whole-digit words → `\d+`, words mixing digits and letters (references,
/// dates, masked accounts) → `\S+`, spaces → `\s+`.
String _loosen(String gap) {
  final out = StringBuffer();
  for (final m in RegExp(r'\S+|\s+').allMatches(gap)) {
    final token = m.group(0)!;
    if (token.trim().isEmpty) {
      out.write(r'\s+');
    } else if (RegExp(r'^\d+$').hasMatch(token)) {
      out.write(r'\d+');
    } else if (RegExp(r'\d').hasMatch(token)) {
      out.write(r'\S+');
    } else {
      out.write(RegExp.escape(token));
    }
  }
  return out.toString();
}
