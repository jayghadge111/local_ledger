import '../rules/parser_rules.dart';

// Turns the cryptic merchant text banks send (`UPI/402910/PYMNT_RZP`,
// `swiggy@icici`, `AMZN MKTP IN`) into a readable name. Runs entirely on
// a bundled table plus the user's own taught aliases — no lookups.

// Bank/gateway plumbing that says nothing about who was paid.

final _vpaPattern = RegExp(r'([A-Za-z0-9._\-]+)@([A-Za-z]+)');

/// [userAliases] maps lowercase raw text fragments to display names the
/// user has taught the app; they win over the bundled table.
String normalizeMerchant(
  String raw, {
  Map<String, String> userAliases = const {},
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();

  for (final entry in userAliases.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }

  // For a VPA, the handle before the "@" is the useful part.
  final vpa = _vpaPattern.firstMatch(trimmed);
  final searchable = vpa != null ? vpa.group(1)! : trimmed;

  for (final alias in ParserRules.current.aliases) {
    if (alias.regex.hasMatch(searchable)) return alias.name;
  }

  return _tidy(searchable, isVpa: vpa != null) ?? _fallbackLabel(lower);
}

// What to call a payment whose text is all bank plumbing ("POS", "UPI/123").
String _fallbackLabel(String lower) {
  if (lower.contains('upi') || lower.contains('@')) return 'UPI payment';
  if (RegExp(r'\b(pos|ecom|ecomm)\b').hasMatch(lower)) return 'Card payment';
  return 'Bank payment';
}

String? _tidy(String text, {required bool isVpa}) {
  final tokens = text
      .replaceAll(RegExp(r'[_\-/*.]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .where((t) => !ParserRules.current.noiseWords.contains(t.toLowerCase()))
      // Long digit runs are reference numbers or phone numbers.
      .where((t) => !(RegExp(r'^\d+$').hasMatch(t) && t.length >= 4 && !isVpa))
      // A VPA like "rahul.sharma42" — drop trailing digits glued to a name.
      .map((t) => isVpa ? t.replaceAll(RegExp(r'\d+$'), '') : t)
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;
  return tokens.map(_titleCase).join(' ');
}

String _titleCase(String word) {
  final lower = word.toLowerCase();
  if (ParserRules.current.acronyms.contains(lower) || word.length <= 2) {
    return word.toUpperCase();
  }
  return word[0].toUpperCase() + lower.substring(1);
}

// What the parser and normalizer call a payment when the message names no
// payee — the *purpose* or the plumbing, not who was paid.

/// True when [text] says what kind of payment this was but not who it was
/// with — "UPI payment", "NEFT transfer", "Home Loan EMI", "ATM withdrawal",
/// or raw bank text that is only plumbing ("UPI/4059...").
///
/// Such a label is shared by many unrelated payments, so a correction made to
/// one of them must never be learned as a rule for the rest.
bool isGenericMerchantLabel(String text) {
  final rules = ParserRules.current;
  final lower = text.trim().toLowerCase();
  if (lower.isEmpty) return true;
  if (rules.genericLabels.contains(lower) ||
      rules.loanEmiLabel.hasMatch(lower)) {
    return true;
  }
  // A payee's own address is specific.
  if (_vpaPattern.hasMatch(lower)) return false;
  return _tidy(lower, isVpa: false) == null;
}
