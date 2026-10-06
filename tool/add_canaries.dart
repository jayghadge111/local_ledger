// Adds anonymised messages copied from the app ("Messages to review" →
// "Share for fixing" → Copy) to the rules' canaries, then regenerates the
// built-in rules.
//
//   dart run tool/add_canaries.dart pasted.json
//
// where pasted.json holds the copied entries (one or several). Afterwards run
// `flutter test test/rules_test.dart`: a message the parser doesn't yet read
// as promised fails there, which is the cue to improve the rules.
import 'dart:convert';
import 'dart:io';

import 'package:local_ledger/core/rules/canary_tools.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/add_canaries.dart <file>');
    exit(64);
  }
  final rulesFile = File('rules/rules.bundled.json');
  final text = rulesFile.readAsStringSync();
  final fresh = newCanaries(
    jsonDecode(text) as Map<String, dynamic>,
    parseSnippets(File(args.single).readAsStringSync()),
  );
  if (fresh.isEmpty) {
    stdout.writeln('Nothing new to add.');
    return;
  }
  final updated = insertCanaries(text, fresh);
  jsonDecode(updated); // must still be valid
  rulesFile.writeAsStringSync(updated);
  stdout.writeln(
    'Added ${fresh.length} canar${fresh.length == 1 ? 'y' : 'ies'}. Now run:',
  );
  stdout.writeln('  dart run tool/gen_bundled_rules.dart');
  stdout.writeln('  flutter test test/rules_test.dart');
}
