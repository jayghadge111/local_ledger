import 'dart:convert';
import 'dart:typed_data';

/// Where updated message-reading rules are published, and who may sign them.
///
/// The rules are a signed file in this repository (`rules/rules.signed.json`,
/// made by `tool/sign_rules.dart`). The app only ever *reads* it, over HTTPS,
/// sending nothing about the user. A file is used only if its signature
/// verifies against one of [kTrustedRulesKeys]; anything else is ignored.
const kRulesUrl = String.fromEnvironment(
  'RULES_URL',
  defaultValue: 'https://raw.githubusercontent.com/jayghadge111/local_ledger/main/rules/rules.signed.json',
);

/// The only `schemaVersion` of the rules format this build can read. A rules
/// file for a newer format waits for an app update instead of being half-read.
const kSupportedRulesSchema = 1;

/// Ed25519 public keys (base64) that may sign rules, by key id. To rotate a
/// key, ship an app update that lists both, then sign with the new one.
final Map<String, Uint8List> kTrustedRulesKeys = {
  '2026-1': base64Decode('LIZjWbxGnTSo/cAJEuV1woiEmXW68sckTdo2MsIdp/0='),
};

/// The largest rules file accepted, in bytes.
const kMaxRulesBytes = 2 * 1024 * 1024;
