import '../rules/parser_rules.dart';
import 'bank_sms_parser.dart';

/// A readable bank name for an SMS sender ID (`VM-HDFCBK-S` -> "HDFC Bank")
/// or an email address (`alerts@hdfcbank.net`), falling back to the raw code.
String bankDisplayName(String sender) {
  if (sender.contains('@')) {
    final domain = sender.split('@').last.toUpperCase();
    for (final segment in domain.split('.')) {
      for (final e in ParserRules.current.bankNames) {
        if (segment.startsWith(e.prefix)) return e.name;
      }
    }
    return domain;
  }
  final code = bankCodeOf(sender);
  for (final e in ParserRules.current.bankNames) {
    if (code.startsWith(e.prefix)) return e.name;
  }
  return code;
}
