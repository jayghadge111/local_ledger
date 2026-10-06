import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A rules file that can't be trusted or used, and why in a few words.
class RulesUpdateException implements Exception {
  RulesUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

const kSignedRulesFormat = 'nativespend-rules-signed';

/// Wraps [payload] (the rules JSON, exactly as text) in a signed envelope.
/// The signature is over the payload's UTF-8 bytes, so there is no
/// re-serialising step where a signature could stop matching.
Future<String> signRules({
  required String payload,
  required String keyId,
  required SimpleKeyPair keyPair,
}) async {
  final signature = await Ed25519().sign(
    utf8.encode(payload),
    keyPair: keyPair,
  );
  return const JsonEncoder.withIndent('  ').convert({
    'format': kSignedRulesFormat,
    'keyId': keyId,
    'signature': base64Encode(signature.bytes),
    'payload': payload,
  });
}

/// Checks the envelope's signature against [trusted] and returns the rules
/// JSON inside. Throws [RulesUpdateException] if the file is not a signed
/// rules file, names a key we do not trust, or does not verify.
Future<String> verifySignedRules(
  String envelopeJson,
  Map<String, Uint8List> trusted,
) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(envelopeJson);
  } catch (_) {
    throw RulesUpdateException('not a JSON file');
  }
  if (decoded is! Map || decoded['format'] != kSignedRulesFormat) {
    throw RulesUpdateException('not a signed rules file');
  }
  final keyId = decoded['keyId'];
  final signature = decoded['signature'];
  final payload = decoded['payload'];
  if (keyId is! String || signature is! String || payload is! String) {
    throw RulesUpdateException('signed rules file is incomplete');
  }
  final key = trusted[keyId];
  if (key == null) {
    throw RulesUpdateException('signed with an unknown key ($keyId)');
  }
  final Uint8List sigBytes;
  try {
    sigBytes = base64Decode(signature);
  } catch (_) {
    throw RulesUpdateException('signature is not valid base64');
  }
  final ok = await Ed25519().verify(
    utf8.encode(payload),
    signature: Signature(
      sigBytes,
      publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
    ),
  );
  if (!ok) throw RulesUpdateException('signature does not match');
  return payload;
}
