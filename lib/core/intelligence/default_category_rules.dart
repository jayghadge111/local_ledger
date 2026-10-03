import '../rules/parser_rules.dart';

/// Built-in merchant keyword -> category, used when the user has no rule of
/// their own. SMS and email carry no category, so the merchant name is all
/// there is to go on; this covers the common Indian merchants and generic
/// words ("cafe", "pharmacy", "recharge"). The user's own rules and
/// corrections always take precedence over these.
///
/// Order matters: the first match wins, so specific names come before
/// generic words (Swiggy Instamart is groceries even though Swiggy is food).
///
/// The keyword lists live in `rules/rules.bundled.json` (see `ParserRules`).

/// The built-in category for [merchantText] (merchant name and/or the raw
/// bank text, joined), or null when nothing matches. [isCredit] lets
/// salary/interest credits land in Income.
String? defaultCategoryFor(String merchantText, {bool isCredit = false}) {
  final rules = ParserRules.current;
  if (isCredit && rules.incomePattern.hasMatch(merchantText)) return 'cat_income';
  for (final (pattern, categoryId) in rules.categoryMatchers) {
    if (pattern.hasMatch(merchantText)) return categoryId;
  }
  return null;
}
