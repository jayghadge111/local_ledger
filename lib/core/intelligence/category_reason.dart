import '../db/app_database.dart';
import '../rules/parser_rules.dart';

/// Why a transaction is in the category it is in, in a sentence.
///
/// Categories come from, in order: what the user chose, the user's own rules
/// (made when they fixed a category), then the built-in word lists. This
/// reports which one applies, so a surprising category can be explained and
/// then fixed — fixing it is what teaches the app.
String categoryReason(
  Transaction t, {
  required List<Rule> rules,
  required String categoryName,
}) {
  final id = t.categoryId;
  if (id == null || id == 'cat_other') {
    return "Nothing in the app's rules matched this one, so it sits in Other. "
        'Choose a category and the app will remember it for next time.';
  }
  if (t.userEdited) {
    return 'You chose $categoryName for this transaction.';
  }

  final names = [t.merchant, if (t.rawMerchant != null) t.rawMerchant!];
  final matching = <Rule>[
    for (final r in rules)
      if (r.categoryId == id &&
          names.any((n) => n.toLowerCase().contains(r.pattern)))
        r,
  ]..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
  if (matching.isNotEmpty) {
    final r = matching.first;
    return r.source == 'user'
        ? 'You taught the app that anything with “${r.pattern}” in the name '
              'is $categoryName.'
        : 'The name contains “${r.pattern}”, which is filed under '
              '$categoryName.';
  }

  final text = names.join(' ');
  for (final (pattern, categoryId) in ParserRules.current.categoryMatchers) {
    if (categoryId != id) continue;
    final m = pattern.firstMatch(text);
    if (m != null) {
      return 'The name contains “${m.group(0)!.trim().toLowerCase()}”, which '
          'the built-in word list files under $categoryName.';
    }
  }
  if (t.type == 'credit' && id == 'cat_income') {
    return 'Money received that reads like income (salary, interest…).';
  }
  return 'Set when this transaction was added ($categoryName).';
}
