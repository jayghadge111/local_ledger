// Signs the message-reading rules so installed apps will accept them.
//
//   dart run tool/sign_rules.dart --generate-key   # once: makes the key pair
//   dart run tool/sign_rules.dart                  # signs rules/rules.bundled.json
//
// The private key lives in rules/signing_key.private (git-ignored: NEVER
// commit it, anyone with it can push rules to every installed app). The
// public half goes in lib/core/rules/rules_config.dart.
//
// To ship a rules fix without an app release:
//   1. edit rules/rules.bundled.json and raise "packVersion"
//   2. dart run tool/gen_bundled_rules.dart && flutter test test/rules_test.dart
//   3. dart run tool/sign_rules.dart
//   4. commit rules/rules.signed.json and push — apps pick it up within a day
//
// Apps check the file's signature, its format version and that every sample
// message in it ("canaries") is read as promised before using it, and keep the
// previous rules so a bad update can be rolled back.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:local_ledger/core/rules/canary_tools.dart';
import 'package:local_ledger/core/rules/parser_rules.dart';
import 'package:local_ledger/core/rules/rules_signing.dart';

const _keyFile = 'rules/signing_key.private';

Future<void> main(List<String> args) async {
  if (args.contains('--generate-key')) {
    final file = File(_keyFile);
    if (file.existsSync()) {
      stderr.writeln('$_keyFile already exists; not overwriting it.');
      exit(1);
    }
    final pair = await Ed25519().newKeyPair();
    final seed = await pair.extractPrivateKeyBytes();
    final pub = (await pair.extractPublicKey()).bytes;
    file.writeAsStringSync('${base64Encode(seed)}\n');
    stdout
      ..writeln('Wrote $_keyFile — keep it secret and backed up.')
      ..writeln('Public key (put it in lib/core/rules/rules_config.dart):')
      ..writeln(base64Encode(pub));
    return;
  }

  final keyId = _option(args, '--key-id') ?? '2026-1';
  final input = _option(args, '--in') ?? 'rules/rules.bundled.json';
  final output = _option(args, '--out') ?? 'rules/rules.signed.json';

  final seedText =
      Platform.environment['RULES_SIGNING_KEY'] ??
      (File(_keyFile).existsSync() ? File(_keyFile).readAsStringSync() : null);
  if (seedText == null) {
    stderr.writeln('No signing key. Run with --generate-key first.');
    exit(1);
  }
  final pair = await Ed25519().newKeyPairFromSeed(
    base64Decode(seedText.trim()),
  );

  final payload = File(input).readAsStringSync();
  final rules = ParserRules.fromJson(jsonDecode(payload) as Map<String, dynamic>);
  final failing = failingCanaries(rules);
  if (failing.isNotEmpty) {
    stderr.writeln('Not signing: these sample messages are not read as promised:');
    for (final f in failing) {
      stderr.writeln('  - $f');
    }
    exit(1);
  }

  final envelope = await signRules(payload: payload, keyId: keyId, keyPair: pair);
  File(output).writeAsStringSync('$envelope\n');
  stdout.writeln(
    'Signed rules pack ${rules.packVersion} (schema ${rules.schemaVersion}) '
    '-> $output',
  );
}

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}
