import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-GCM encryption for everything that touches the local database.
///
/// The data encryption key is a random 256-bit key generated once on first
/// launch and held in the platform secure store (Keychain / Keystore /
/// WebCrypto-backed storage on web). Nothing here ever leaves the device.
class EncryptionService {
  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keyStorageKey = 'local_ledger.aes_master_key';

  final FlutterSecureStorage _secureStorage;
  final _algorithm = AesGcm.with256bits();

  SecretKey? _cachedKey;

  Future<SecretKey> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null) {
      final bytes = base64Decode(existing);
      _cachedKey = SecretKey(bytes);
      return _cachedKey!;
    }

    final newKey = await _algorithm.newSecretKey();
    final bytes = await newKey.extractBytes();
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64Encode(bytes),
    );
    _cachedKey = newKey;
    return newKey;
  }

  /// Encrypts [plainText] and returns a single base64 string containing
  /// nonce + ciphertext + MAC, safe to store directly in a text column.
  Future<String> encryptString(String plainText) async {
    final key = await _getOrCreateKey();
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    return base64Encode(secretBox.concatenation());
  }

  Future<String> decryptString(String encoded) async {
    final key = await _getOrCreateKey();
    final bytes = base64Decode(encoded);
    final secretBox = SecretBox.fromConcatenation(
      bytes,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final plainBytes = await _algorithm.decrypt(secretBox, secretKey: key);
    return utf8.decode(plainBytes);
  }

  /// Encrypts arbitrary bytes with an explicit key rather than the
  /// device-bound one — used for exporting a backup with a user passphrase,
  /// since the device key never leaves this install and would be useless
  /// for decrypting a backup after a reinstall or on another device.
  Future<Uint8List> encryptBytesWithKey(List<int> bytes, List<int> keyBytes) async {
    final key = SecretKey(keyBytes);
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(bytes, secretKey: key, nonce: nonce);
    return Uint8List.fromList(secretBox.concatenation());
  }

  Future<Uint8List> decryptBytesWithKey(List<int> bytes, List<int> keyBytes) async {
    final key = SecretKey(keyBytes);
    final secretBox = SecretBox.fromConcatenation(
      bytes,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    final plainBytes = await _algorithm.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(plainBytes);
  }

  /// Derives a key from a user passphrase using PBKDF2-HMAC-SHA512. Used
  /// for the encrypted export/backup feature (see [encryptBytesWithKey]) —
  /// not the same key as the day-to-day on-device data encryption above.
  Future<Uint8List> deriveKeyFromPassphrase(
    String passphrase,
    List<int> salt, {
    int iterations = 210000,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }
}
