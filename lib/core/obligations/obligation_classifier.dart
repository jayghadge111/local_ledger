import '../rules/parser_rules.dart';

/// What a message about an auto-debit says it is.
enum ObligationKind {
  /// An e-mandate / NACH / UPI AutoPay was set up (UMRN, biller, max cap).
  mandate('mandate'),

  /// A debit is scheduled for a date (the 24–48 hour notice). Not a spend yet.
  preDebit('pre_debit'),

  /// A loan EMI or instalment is due.
  emiDue('emi_due'),

  /// A credit card bill: total due, minimum due, due date.
  cardDue('card_due'),

  /// An auto-debit failed or was returned.
  bounce('bounce');

  const ObligationKind(this.key);

  /// The value stored in the database.
  final String key;

  static ObligationKind? fromKey(String key) {
    for (final k in values) {
      if (k.key == key) return k;
    }
    return null;
  }
}

ObligationPatterns get _o => ParserRules.current.obligations;

String flatText(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Which kind of auto-debit notice [text] is, or null if it isn't one. Strict
/// on purpose: a debit that has already happened ("debited from A/c … towards
/// … UMRN …") is a transaction, not a notice.
ObligationKind? classifyObligation(String text) {
  final t = flatText(text);
  if (_o.bounce.hasMatch(t)) return ObligationKind.bounce;
  if (_o.setup.hasMatch(t)) return ObligationKind.mandate;
  final isCard = _o.cardWords.hasMatch(t) && _o.totalDueWords.hasMatch(t);
  if (isCard && _o.cardStatement.hasMatch(t)) return ObligationKind.cardDue;
  if (_o.preDebit.hasMatch(t)) {
    if (isCard) return ObligationKind.cardDue;
    if (_o.emiWords.hasMatch(t)) return ObligationKind.emiDue;
    return ObligationKind.preDebit;
  }
  if (_o.cardDue.hasMatch(t)) return ObligationKind.cardDue;
  if (_o.emiDue.hasMatch(t)) return ObligationKind.emiDue;
  return null;
}
