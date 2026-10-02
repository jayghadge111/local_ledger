// Turns the cryptic merchant text banks send (`UPI/402910/PYMNT_RZP`,
// `swiggy@icici`, `AMZN MKTP IN`) into a readable name. Runs entirely on
// a bundled table plus the user's own taught aliases — no lookups.

/// A bundled alias: any raw text containing [pattern] as a whole word
/// becomes [displayName].
class _Alias {
  _Alias(String pattern, this.displayName)
      : regex = RegExp(r'(?<![a-z0-9])' + RegExp.escape(pattern) + r'(?![a-z0-9])', caseSensitive: false);
  final RegExp regex;
  final String displayName;
}

final _bundledAliases = <_Alias>[
  _Alias('swiggy', 'Swiggy'),
  _Alias('zomato', 'Zomato'),
  _Alias('zepto', 'Zepto'),
  _Alias('blinkit', 'Blinkit'),
  _Alias('bigbasket', 'BigBasket'),
  _Alias('amzn', 'Amazon'),
  _Alias('amazon', 'Amazon'),
  _Alias('flipkart', 'Flipkart'),
  _Alias('myntra', 'Myntra'),
  _Alias('nykaa', 'Nykaa'),
  _Alias('ajio', 'Ajio'),
  _Alias('uber', 'Uber'),
  _Alias('olacabs', 'Ola'),
  _Alias('ola', 'Ola'),
  _Alias('rapido', 'Rapido'),
  _Alias('irctc', 'IRCTC'),
  _Alias('makemytrip', 'MakeMyTrip'),
  _Alias('redbus', 'redBus'),
  _Alias('bookmyshow', 'BookMyShow'),
  _Alias('netflix', 'Netflix'),
  _Alias('spotify', 'Spotify'),
  _Alias('hotstar', 'Hotstar'),
  _Alias('primevideo', 'Prime Video'),
  _Alias('youtube', 'YouTube'),
  _Alias('google play', 'Google Play'),
  _Alias('googleplay', 'Google Play'),
  _Alias('apple.com/bill', 'Apple'),
  _Alias('apple', 'Apple'),
  _Alias('jio', 'Jio'),
  _Alias('airtel', 'Airtel'),
  _Alias('vodafone', 'Vi'),
  _Alias('bescom', 'BESCOM'),
  _Alias('starbucks', 'Starbucks'),
  _Alias('mcdonalds', "McDonald's"),
  _Alias('dominos', "Domino's"),
  _Alias('kfc', 'KFC'),
  _Alias('dmart', 'DMart'),
  _Alias('cred', 'CRED'),
  _Alias('phonepe', 'PhonePe'),
  _Alias('paytm', 'Paytm'),
  _Alias('practo', 'Practo'),
  _Alias('apollo', 'Apollo'),
];

// Bank/gateway plumbing that says nothing about who was paid.
const _noiseWords = {
  'upi', 'imps', 'neft', 'rtgs', 'pymnt', 'payment', 'pay', 'txn', 'ref', 'dr', 'cr',
  'pos', 'ecom', 'ecomm', 'ib', 'mb', 'ach', 'nach', 'mandate', 'purchase', 'to', 'from',
  'rzp', 'rzpx', 'razorpay', 'payu', 'pyu', 'ccavenue', 'billdesk', 'cashfree', 'ppsl',
};

final _vpaPattern = RegExp(r'([A-Za-z0-9._\-]+)@([A-Za-z]+)');

/// [userAliases] maps lowercase raw text fragments to display names the
/// user has taught the app; they win over the bundled table.
String normalizeMerchant(String raw, {Map<String, String> userAliases = const {}}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();

  for (final entry in userAliases.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }

  // For a VPA, the handle before the "@" is the useful part.
  final vpa = _vpaPattern.firstMatch(trimmed);
  final searchable = vpa != null ? vpa.group(1)! : trimmed;

  for (final alias in _bundledAliases) {
    if (alias.regex.hasMatch(searchable)) return alias.displayName;
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
      .where((t) => !_noiseWords.contains(t.toLowerCase()))
      // Long digit runs are reference numbers or phone numbers.
      .where((t) => !(RegExp(r'^\d+$').hasMatch(t) && t.length >= 4 && !isVpa))
      // A VPA like "rahul.sharma42" — drop trailing digits glued to a name.
      .map((t) => isVpa ? t.replaceAll(RegExp(r'\d+$'), '') : t)
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;
  return tokens.map(_titleCase).join(' ');
}

const _acronyms = {
  'hdfc', 'icici', 'sbi', 'lic', 'irctc', 'bsnl', 'atm', 'emi', 'kfc', 'dmart', 'pnb', 'bob',
  'tcs', 'ibm', 'hp', 'ev', 'ac',
};

String _titleCase(String word) {
  final lower = word.toLowerCase();
  if (_acronyms.contains(lower) || word.length <= 2) return word.toUpperCase();
  return word[0].toUpperCase() + lower.substring(1);
}
