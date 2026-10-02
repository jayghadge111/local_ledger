/// Built-in merchant keyword -> category, used when the user has no rule of
/// their own. SMS and email carry no category, so the merchant name is all
/// there is to go on; this covers the common Indian merchants and generic
/// words ("cafe", "pharmacy", "recharge"). The user's own rules and
/// corrections always take precedence over these.
///
/// Order matters: the first match wins, so specific names come before
/// generic words (Swiggy Instamart is groceries even though Swiggy is food).
const _rules = <(String, List<String>)>[
  ('cat_groceries', [
    'instamart', 'blinkit', 'zepto', 'bigbasket', 'grofers', 'dmart', 'jiomart', 'more retail',
    'reliance fresh', 'nature basket', 'supermarket', 'grocery', 'groceries', 'kirana',
    'vegetable', 'vegetables', 'fruits', 'milk', 'dairy',
  ]),
  ('cat_food', [
    'swiggy', 'zomato', 'starbucks', 'mcdonalds', "mcdonald's", 'dominos', "domino's", 'kfc',
    'burger king', 'subway', 'pizza', 'burger', 'cafe', 'coffee', 'tea', 'chai', 'restaurant',
    'bakery', 'biryani', 'canteen', 'dining', 'eats', 'kitchen', 'dhaba', 'juice', 'ice cream',
    'food', 'bar', 'pub', 'brewery',
  ]),
  ('cat_transport', [
    'uber', 'ola', 'rapido', 'redbus', 'irctc', 'railway', 'metro', 'fastag', 'toll', 'parking',
    'petrol', 'diesel', 'fuel', 'indian oil', 'iocl', 'bpcl', 'hpcl', 'shell', 'air india',
    'indigo', 'spicejet', 'vistara', 'akasa', 'makemytrip', 'goibibo', 'cleartrip', 'bmtc',
    'ksrtc', 'msrtc', 'cab', 'taxi', 'auto',
  ]),
  ('cat_entertainment', [
    'netflix', 'spotify', 'hotstar', 'primevideo', 'prime video', 'youtube', 'bookmyshow',
    'pvr', 'inox', 'sonyliv', 'zee5', 'jiocinema', 'gaana', 'steam', 'playstation', 'xbox',
    'google play', 'cinema', 'movies', 'gaming',
  ]),
  ('cat_health', [
    'apollo', 'practo', 'pharmeasy', 'netmeds', '1mg', 'medplus', 'pharmacy', 'pharma',
    'chemist', 'hospital', 'clinic', 'medical', 'diagnostic', 'diagnostics', 'dental', 'lab',
    'doctor', 'healthcare', 'fitness', 'gym', 'cult.fit', 'cultfit',
  ]),
  ('cat_bills', [
    'bescom', 'mseb', 'tneb', 'electricity', 'airtel', 'jio', 'vodafone', 'bsnl', 'recharge',
    'broadband', 'fibernet', 'postpaid', 'prepaid recharge', 'dth', 'tata play', 'tatasky',
    'gas', 'water bill', 'insurance', 'lic', 'emi', 'loan', 'bill', 'utility', 'municipal',
    'rent', 'maintenance', 'society',
  ]),
  ('cat_shopping', [
    'amazon', 'amzn', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho', 'croma',
    'reliance digital', 'lifestyle', 'decathlon', 'ikea', 'tata cliq', 'shoppers stop',
    'westside', 'pantaloons', 'mall', 'store', 'mart', 'fashion', 'electronics',
  ]),
];

// Credits that are income rather than "Other".
const _incomeWords = ['salary', 'interest', 'dividend', 'payroll', 'bonus', 'stipend'];

final _compiled = [
  for (final (categoryId, words) in _rules)
    for (final w in words)
      (RegExp(r'(?<![a-z0-9])' + RegExp.escape(w) + r'(?![a-z0-9])', caseSensitive: false), categoryId),
];

final _incomePattern = RegExp(
  r'(?<![a-z0-9])(?:' + _incomeWords.join('|') + r')(?![a-z0-9])',
  caseSensitive: false,
);

/// The built-in category for [merchantText] (merchant name and/or the raw
/// bank text, joined), or null when nothing matches. [isCredit] lets
/// salary/interest credits land in Income.
String? defaultCategoryFor(String merchantText, {bool isCredit = false}) {
  if (isCredit && _incomePattern.hasMatch(merchantText)) return 'cat_income';
  for (final (pattern, categoryId) in _compiled) {
    if (pattern.hasMatch(merchantText)) return categoryId;
  }
  return null;
}
