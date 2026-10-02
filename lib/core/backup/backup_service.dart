import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';
import '../security/encryption_service.dart';

const _backupFormat = 'local_ledger_backup_v1';

/// Exports/imports all local data as a single passphrase-encrypted file.
///
/// Deliberately keyed by a passphrase the user chooses (via PBKDF2-HMAC-
/// SHA512, see [EncryptionService.deriveKeyFromPassphrase]) rather than the
/// device-bound AES key everything else in the app uses: that key lives in
/// this install's secure storage and would be useless for decrypting a
/// backup after a reinstall or on another device. The file itself is just
/// JSON — never sent anywhere, the user chooses where it's saved or shared.
class BackupService {
  BackupService(this._db, this._encryption);

  final AppDatabase _db;
  final EncryptionService _encryption;

  Future<File> exportEncrypted(String passphrase) async {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': (await _db.select(_db.accounts).get()).map((e) => e.toJson()).toList(),
      'categories': (await _db.select(_db.categories).get()).map((e) => e.toJson()).toList(),
      'transactions':
          (await _db.select(_db.transactions).get()).map((e) => e.toJson()).toList(),
      'budgets': (await _db.select(_db.budgets).get()).map((e) => e.toJson()).toList(),
      'rules': (await _db.select(_db.rules).get()).map((e) => e.toJson()).toList(),
      'ownIdentifiers':
          (await _db.select(_db.ownIdentifiers).get()).map((e) => e.toJson()).toList(),
      'merchantAliases':
          (await _db.select(_db.merchantAliases).get()).map((e) => e.toJson()).toList(),
      'splitShares': (await _db.select(_db.splitShares).get()).map((e) => e.toJson()).toList(),
    };
    final jsonBytes = utf8.encode(jsonEncode(payload));

    final salt = _randomBytes(16);
    final key = await _encryption.deriveKeyFromPassphrase(passphrase, salt);
    final encryptedBytes = await _encryption.encryptBytesWithKey(jsonBytes, key);

    final envelope = jsonEncode({
      'format': _backupFormat,
      'salt': base64Encode(salt),
      'data': base64Encode(encryptedBytes),
    });

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/local_ledger_backup_$timestamp.llbackup');
    await file.writeAsString(envelope);
    return file;
  }

  /// Throws [FormatException] for a non-backup file and
  /// [BackupPassphraseException] for a wrong passphrase.
  Future<void> importEncrypted(File file, String passphrase) async {
    final envelope = jsonDecode(await file.readAsString());
    if (envelope is! Map || envelope['format'] != _backupFormat) {
      throw const FormatException('Not a LocalLedger backup file');
    }

    final salt = base64Decode(envelope['salt'] as String);
    final data = base64Decode(envelope['data'] as String);
    final key = await _encryption.deriveKeyFromPassphrase(passphrase, salt);

    final List<int> jsonBytes;
    try {
      jsonBytes = await _encryption.decryptBytesWithKey(data, key);
    } catch (_) {
      throw BackupPassphraseException();
    }

    final payload = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

    await _db.transaction(() async {
      for (final row in (payload['accounts'] as List? ?? [])) {
        await _db.into(_db.accounts).insertOnConflictUpdate(
              Account.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
      for (final row in (payload['categories'] as List? ?? [])) {
        await _db.into(_db.categories).insertOnConflictUpdate(
              Category.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
      for (final row in (payload['transactions'] as List? ?? [])) {
        await _db.into(_db.transactions).insertOnConflictUpdate(
              // Backups from before schema v3 lack the newer columns.
              Transaction.fromJson({
                'kind': 'normal',
                'kindLocked': false,
                'refundHint': false,
                ...(row as Map<String, dynamic>),
              }).toCompanion(true),
            );
      }
      for (final row in (payload['budgets'] as List? ?? [])) {
        await _db.into(_db.budgets).insertOnConflictUpdate(
              Budget.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
      for (final row in (payload['rules'] as List? ?? [])) {
        await _db.into(_db.rules).insertOnConflictUpdate(
              Rule.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
      for (final row in (payload['ownIdentifiers'] as List? ?? [])) {
        await _db.into(_db.ownIdentifiers).insertOnConflictUpdate(
              OwnIdentifier.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
      for (final row in (payload['merchantAliases'] as List? ?? [])) {
        await _db.into(_db.merchantAliases).insertOnConflictUpdate(
              MerchantAliase.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
      for (final row in (payload['splitShares'] as List? ?? [])) {
        await _db.into(_db.splitShares).insertOnConflictUpdate(
              SplitShare.fromJson(row as Map<String, dynamic>).toCompanion(true),
            );
      }
    });
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

class BackupPassphraseException implements Exception {}
