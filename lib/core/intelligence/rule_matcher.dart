import '../db/app_database.dart';

/// Finds the best-matching category rule for a merchant name — highest
/// [Rule.priority] wins among matches, ties broken by longest pattern
/// (more specific). Used both for auto-categorizing manual entries and,
/// later, for incoming SMS/email parses.
String? matchCategoryForMerchant(String merchant, List<Rule> rules) {
  final lower = merchant.toLowerCase();
  Rule? best;
  for (final rule in rules) {
    if (!lower.contains(rule.pattern)) continue;
    if (best == null ||
        rule.priority > best.priority ||
        (rule.priority == best.priority && rule.pattern.length > best.pattern.length)) {
      best = rule;
    }
  }
  return best?.categoryId;
}
