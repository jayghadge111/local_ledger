import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// SHA-512 hashing for things that must never be reversible — the app-lock
/// PIN/passphrase. The PIN itself is never stored, only this hash + salt.
class HashingService {
  const HashingService();

  /// Generates a random 16-byte salt, base64-encoded.
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// SHA-512 of `salt + value`, returned as a hex string.
  String hash(String value, String salt) {
    final bytes = utf8.encode(salt + value);
    return sha512.convert(bytes).toString();
  }

  bool verify(String value, String salt, String expectedHash) {
    return hash(value, salt) == expectedHash;
  }
}
