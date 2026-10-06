import 'dart:convert';

import '../sms/bank_sms_parser.dart';
import 'parser_rules.dart';

/// The entries of [snippets] (copied from the app — one object or a list)
/// that are worth adding to the rules' `canaries`: well formed, and not
/// already there (same text). Each one added becomes a permanent regression
/// test: `test/rules_test.dart` reads every canary and checks the parser still
/// reads it as promised.
List<Map<String, dynamic>> newCanaries(
  Map<String, dynamic> rulesJson,
  Object snippets,
) {
  final known = {
    for (final c in (rulesJson['canaries'] as List).cast<Map<String, dynamic>>())
      (c['text'] as String).trim(),
  };
  final incoming = snippets is List ? snippets : [snippets];
  final fresh = <Map<String, dynamic>>[];
  for (final entry in incoming) {
    if (entry is! Map<String, dynamic>) continue;
    final text = entry['text'];
    final expect = entry['expect'];
    if (text is! String || text.trim().isEmpty || expect is! Map) continue;
    if (!known.add(text.trim())) continue;
    fresh.add({'text': text, 'expect': expect});
  }
  return fresh;
}

/// Inserts [entries] at the end of the `canaries` list in the rules file's
/// text, leaving every other byte of the file alone (so the diff is just the
/// new entries).
String insertCanaries(String rulesText, List<Map<String, dynamic>> entries) {
  if (entries.isEmpty) return rulesText;
  final key = rulesText.indexOf('"canaries"');
  final open = rulesText.indexOf('[', key);
  var depth = 0;
  var inString = false;
  var close = -1;
  for (var i = open; i < rulesText.length; i++) {
    final c = rulesText[i];
    if (inString) {
      if (c == '\\') {
        i++;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
    } else if (c == '[') {
      depth++;
    } else if (c == ']') {
      depth--;
      if (depth == 0) {
        close = i;
        break;
      }
    }
  }
  if (key < 0 || open < 0 || close < 0) {
    throw const FormatException('no "canaries" list in the rules file');
  }
  const encoder = JsonEncoder.withIndent('  ');
  final block = entries
      .map((e) => encoder.convert(e).split('\n').map((l) => '    $l').join('\n'))
      .join(',\n');
  final before = rulesText.substring(0, close).trimRight();
  return '$before,\n$block\n  ${rulesText.substring(close)}';
}

/// Reads one or several pasted JSON entries — a single object, a list, or
/// several objects one after another — from [pasted].
Object parseSnippets(String pasted) {
  final trimmed = pasted.trim();
  try {
    return jsonDecode(trimmed) as Object;
  } on FormatException {
    // "{...}\n{...}": wrap into a list.
    return jsonDecode('[${trimmed.replaceAll(RegExp(r'\}\s*\{'), '},{')}]')
        as Object;
  }
}

/// The canaries (see [RuleCanary]) that [rules] fail to read as promised, each
/// as a short description. Empty means the rules are sound. The rules are put
/// in force only while this runs.
List<String> failingCanaries(ParserRules rules) {
  final failures = <String>[];
  final previous = ParserRules.current;
  ParserRules.use(rules);
  try {
    for (final c in rules.canaries) {
      final label = c.text.replaceAll(RegExp(r'\s+'), ' ');
      final short = label.length > 50 ? '${label.substring(0, 50)}…' : label;
      final parsed = parseBankSms(c.text);
      if (c.type == null) {
        if (parsed != null) failures.add('should be ignored: $short');
        continue;
      }
      if (parsed == null) {
        failures.add('not read: $short');
      } else if (parsed.type != c.type) {
        failures.add('wrong direction: $short');
      } else if (c.amountMinor != null && parsed.amountMinor != c.amountMinor) {
        failures.add('wrong amount: $short');
      } else if (c.merchantContains != null &&
          !parsed.merchant.toLowerCase().contains(
            c.merchantContains!.toLowerCase(),
          )) {
        failures.add('wrong payee: $short');
      }
    }
  } finally {
    ParserRules.use(previous);
  }
  return failures;
}
